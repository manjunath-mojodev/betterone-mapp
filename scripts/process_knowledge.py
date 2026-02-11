#!/usr/bin/env python3
"""
process_knowledge.py — Extract structured coaching knowledge from PDFs
for the BetterOne iOS app's DefaultKnowledge.json.

Usage:
    python3 scripts/process_knowledge.py <pdf_path_or_directory> [options]

Examples:
    python3 scripts/process_knowledge.py coaching-guide.pdf --dry-run --verbose
    python3 scripts/process_knowledge.py ./pdfs/ --provider openai
    python3 scripts/process_knowledge.py transcript.pdf --source-name "YouTube: Life OS"

Requires: ANTHROPIC_API_KEY or OPENAI_API_KEY env var depending on --provider.
"""

import argparse
import json
import os
import re
import sys
import time
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Optional


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

VALID_TOPIC_SLUGS = [
    "notion-life-os",
    "simplified-life-os",
    "second-brain",
    "client-content-os",
    "goal-setting",
    "habit-tracking",
    "task-project-management",
    "ai-agent-os",
    "notion-foundations",
    "productivity-principles",
    "info-org-capture",
    "design-workspace",
]

VALID_ROLES = ["knowledge", "persona_signal", "boundary_risk"]

TOPIC_DESCRIPTIONS = {
    "notion-life-os": "Comprehensive Notion life operating system — tasks, goals, habits, knowledge unified",
    "simplified-life-os": "Beginner-friendly simplified Notion setup, paper-planner inspired",
    "second-brain": "Knowledge management, capturing and retrieving ideas, PARA, progressive summarization",
    "client-content-os": "Client management, content pipelines, freelancing, CRM",
    "goal-setting": "Goals, planning, yearly/quarterly reviews, milestones",
    "habit-tracking": "Habits, consistency, routine building, Atomic Habits",
    "task-project-management": "Tasks, projects, priorities, dashboards, daily planning",
    "ai-agent-os": "AI agents, prompt engineering, agent design, AgentOS framework",
    "notion-foundations": "Notion basics, databases, relations, formulas, views",
    "productivity-principles": "Productivity philosophy, workflows, essentialism, deep work, decision frameworks",
    "info-org-capture": "Information organization, idea capture systems, GTD inbox processing",
    "design-workspace": "Notion aesthetics, dashboard design, visual layout, workspace customization",
}

DEFAULT_OUTPUT = "betterone/Resources/DefaultKnowledge.json"

CLAUDE_MODEL = "claude-sonnet-4-20250514"
OPENAI_MODEL = "gpt-4o"
LLM_TEMPERATURE = 0.3
LLM_MAX_TOKENS = 1024


# ---------------------------------------------------------------------------
# Data Structures
# ---------------------------------------------------------------------------

@dataclass
class KnowledgeEntry:
    topicSlug: str
    coreIdea: str
    whenToUse: str
    heuristics: list
    whatToAvoid: list
    sourceReference: str
    role: str

    def to_dict(self) -> dict:
        return asdict(self)


# ---------------------------------------------------------------------------
# PDF Text Extraction
# ---------------------------------------------------------------------------

def extract_text_from_pdf(pdf_path: str, verbose: bool = False) -> str:
    """Extract all text from a PDF file using pymupdf."""
    import fitz  # pymupdf

    doc = fitz.open(pdf_path)
    pages = []
    for page_num, page in enumerate(doc):
        text = page.get_text()
        if text.strip():
            pages.append(text)
        elif verbose:
            print(f"  [warn] Page {page_num + 1}: no extractable text")

    doc.close()
    full_text = "\n\n".join(pages)

    if verbose:
        print(f"  Extracted {len(full_text)} chars from {len(pages)} pages")

    return full_text


# ---------------------------------------------------------------------------
# Transcript Detection & Preprocessing
# ---------------------------------------------------------------------------

_TIMESTAMP_RE = re.compile(r"^\s*\[?\d{1,2}:\d{2}(:\d{2})?\]?\s*$")


def is_transcript_format(text: str) -> bool:
    """Heuristic: if >10% of lines match timestamp pattern, it's a transcript."""
    lines = text.split("\n")
    if not lines:
        return False
    count = sum(1 for line in lines if _TIMESTAMP_RE.match(line.strip()))
    return count / len(lines) > 0.10


def preprocess_transcript(text: str) -> str:
    """Strip timestamp lines and collapse into paragraphs."""
    lines = text.split("\n")
    cleaned = []
    for line in lines:
        if _TIMESTAMP_RE.match(line.strip()):
            if cleaned and cleaned[-1] != "":
                cleaned.append("")
        else:
            cleaned.append(line)
    return "\n".join(cleaned)


# ---------------------------------------------------------------------------
# Text Chunking (mirrors KnowledgeProcessor.swift chunkByIdea)
# ---------------------------------------------------------------------------

def chunk_by_idea(text: str, verbose: bool = False) -> list:
    """
    Split text into idea-sized chunks.
    - New chunk on markdown headings (# ## ###) or bold headings
    - New chunk on paragraph breaks when current chunk has >3 lines
    - Merge chunks smaller than 100 chars with the previous
    """
    lines = text.split("\n")
    chunks = []
    current_chunk = []

    for line in lines:
        trimmed = line.strip()
        is_heading = (
            trimmed.startswith("# ")
            or trimmed.startswith("## ")
            or trimmed.startswith("### ")
            or (trimmed.startswith("**") and trimmed.endswith("**") and len(trimmed) > 4)
        )
        is_empty = len(trimmed) == 0

        if is_heading and current_chunk:
            chunks.append(current_chunk)
            current_chunk = [line]
        elif is_empty and len(current_chunk) > 3:
            chunks.append(current_chunk)
            current_chunk = []
        elif not is_empty:
            current_chunk.append(line)

    if current_chunk:
        chunks.append(current_chunk)

    # Join lines within each chunk
    joined = ["\n".join(c) for c in chunks]

    # Merge small chunks (<100 chars) with the previous
    merged = []
    for chunk in joined:
        if merged and len(merged[-1]) < 100:
            merged[-1] = merged[-1] + "\n" + chunk
        else:
            merged.append(chunk)

    if verbose:
        print(f"  Split into {len(merged)} chunks (from {len(joined)} raw)")

    return merged


# ---------------------------------------------------------------------------
# LLM Provider Abstraction
# ---------------------------------------------------------------------------

def call_llm(
    system_prompt: str,
    user_prompt: str,
    provider: str,
    verbose: bool = False,
) -> str:
    """Send a message to the configured LLM. Retries on rate limits."""
    for attempt in range(3):
        try:
            if provider == "claude":
                return _call_claude(system_prompt, user_prompt)
            elif provider == "openai":
                return _call_openai(system_prompt, user_prompt)
            else:
                raise ValueError(f"Unknown provider: {provider}")
        except Exception as e:
            err = str(e).lower()
            if "rate" in err or "429" in err:
                wait = 2 ** (attempt + 1)
                if verbose:
                    print(f"  [rate-limit] Waiting {wait}s...")
                time.sleep(wait)
                continue
            raise
    raise RuntimeError("Failed after 3 retries")


def _call_claude(system_prompt: str, user_prompt: str) -> str:
    import anthropic

    client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
    response = client.messages.create(
        model=CLAUDE_MODEL,
        max_tokens=LLM_MAX_TOKENS,
        temperature=LLM_TEMPERATURE,
        system=system_prompt,
        messages=[{"role": "user", "content": user_prompt}],
    )
    return response.content[0].text


def _call_openai(system_prompt: str, user_prompt: str) -> str:
    import openai

    client = openai.OpenAI(api_key=os.environ["OPENAI_API_KEY"])
    response = client.chat.completions.create(
        model=OPENAI_MODEL,
        max_tokens=LLM_MAX_TOKENS,
        temperature=LLM_TEMPERATURE,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
    )
    return response.choices[0].message.content


# ---------------------------------------------------------------------------
# Step 3: Classification (mirrors KnowledgeProcessor.swift classify)
# ---------------------------------------------------------------------------

CLASSIFY_SYSTEM = "You are a concise text classifier. Respond in the exact format specified."


def _build_classify_prompt(chunk_text: str) -> str:
    truncated = chunk_text[:1000]
    topic_lines = "\n".join(
        f"- {slug}: {desc}" for slug, desc in TOPIC_DESCRIPTIONS.items()
    )
    slugs_csv = ", ".join(VALID_TOPIC_SLUGS)

    return f"""Classify the following text chunk from a coaching knowledge base.

TEXT:
{truncated}

Respond with EXACTLY two lines:
TOPIC: <one of: {slugs_csv}>
ROLE: <one of: knowledge, persona_signal, boundary_risk>

Topic guide:
{topic_lines}

Role definitions:
- knowledge: Coaching frameworks, advice, methods, strategies
- persona_signal: Indicators of the creator's voice, tone, beliefs, style
- boundary_risk: Content about limitations, what not to do, safety concerns"""


def _parse_classification(response: str) -> tuple:
    topic_slug = "productivity-principles"
    role = "knowledge"

    for line in response.split("\n"):
        trimmed = line.strip()
        upper = trimmed.upper()
        if upper.startswith("TOPIC:"):
            value = trimmed[len("TOPIC:"):].strip().lower()
            if value in VALID_TOPIC_SLUGS:
                topic_slug = value
        elif upper.startswith("ROLE:"):
            value = trimmed[len("ROLE:"):].strip().lower()
            if value in VALID_ROLES:
                role = value

    return topic_slug, role


def classify_chunk(chunk_text: str, provider: str, verbose: bool = False) -> tuple:
    """Classify a chunk into (topic_slug, role)."""
    prompt = _build_classify_prompt(chunk_text)
    response = call_llm(CLASSIFY_SYSTEM, prompt, provider, verbose)
    if verbose:
        print(f"    Classification: {response.strip()}")
    return _parse_classification(response)


# ---------------------------------------------------------------------------
# Step 4: Knowledge Extraction (mirrors KnowledgeProcessor.swift extract)
# ---------------------------------------------------------------------------

EXTRACT_SYSTEM = "You are a knowledge extraction specialist. Respond in the exact format specified."


def _build_extract_prompt(chunk_text: str) -> str:
    truncated = chunk_text[:1500]

    return f"""Extract a structured coaching knowledge object from the following text.

TEXT:
{truncated}

Respond in this exact format (each field on its own line):
CORE_IDEA: <one sentence summarizing the main coaching coaching insight>
WHEN_TO_USE: <when a coach should apply this idea>
HEURISTICS: <2-3 practical guidelines, separated by |>
WHAT_TO_AVOID: <1-2 things to avoid, separated by |>

Be concise. Each field should be 1-2 sentences max."""


def _parse_knowledge_object(
    response: str,
    topic_slug: str,
    role: str,
    source_reference: str,
) -> Optional[KnowledgeEntry]:
    core_idea = ""
    when_to_use = ""
    heuristics = []
    what_to_avoid = []

    for line in response.split("\n"):
        trimmed = line.strip()
        upper = trimmed.upper()

        if upper.startswith("CORE_IDEA:"):
            core_idea = trimmed[len("CORE_IDEA:"):].strip()
        elif upper.startswith("WHEN_TO_USE:"):
            when_to_use = trimmed[len("WHEN_TO_USE:"):].strip()
        elif upper.startswith("HEURISTICS:"):
            value = trimmed[len("HEURISTICS:"):].strip()
            heuristics = [h.strip() for h in value.split("|") if h.strip()]
        elif upper.startswith("WHAT_TO_AVOID:"):
            value = trimmed[len("WHAT_TO_AVOID:"):].strip()
            what_to_avoid = [w.strip() for w in value.split("|") if w.strip()]

    if not core_idea:
        return None

    return KnowledgeEntry(
        topicSlug=topic_slug,
        coreIdea=core_idea,
        whenToUse=when_to_use,
        heuristics=heuristics,
        whatToAvoid=what_to_avoid,
        sourceReference=source_reference,
        role=role,
    )


def extract_from_chunk(
    chunk_text: str,
    topic_slug: str,
    role: str,
    source_reference: str,
    provider: str,
    verbose: bool = False,
) -> Optional[KnowledgeEntry]:
    """Run knowledge extraction on a single chunk."""
    prompt = _build_extract_prompt(chunk_text)
    response = call_llm(EXTRACT_SYSTEM, prompt, provider, verbose)
    if verbose:
        print(f"    Extraction: {response.strip()[:200]}...")
    return _parse_knowledge_object(response, topic_slug, role, source_reference)


# ---------------------------------------------------------------------------
# Deduplication & Merge
# ---------------------------------------------------------------------------

def is_duplicate(new_entry: KnowledgeEntry, existing: list) -> bool:
    """Dedup by sourceReference + first 60 chars of coreIdea."""
    new_prefix = new_entry.coreIdea[:60].lower().strip()
    new_source = new_entry.sourceReference.lower().strip()

    for entry in existing:
        src = entry.get("sourceReference", "").lower().strip()
        prefix = entry.get("coreIdea", "")[:60].lower().strip()
        if src == new_source and prefix == new_prefix:
            return True
    return False


def load_existing(output_path: str) -> list:
    """Load existing JSON, return [] if not found."""
    path = Path(output_path)
    if not path.exists():
        return []
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def save_knowledge(entries: list, output_path: str) -> None:
    """Write entries to JSON with pretty formatting."""
    path = Path(output_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(entries, f, indent=4, ensure_ascii=False)
        f.write("\n")


# ---------------------------------------------------------------------------
# Pipeline
# ---------------------------------------------------------------------------

def process_single_pdf(
    pdf_path: str,
    provider: str,
    source_name: Optional[str],
    verbose: bool,
) -> list:
    """Full pipeline for one PDF file."""
    filename = Path(pdf_path).stem
    source_ref = source_name or filename

    print(f"\nProcessing: {pdf_path}")
    print(f"  Source: {source_ref}")

    # Step 1: Extract text
    text = extract_text_from_pdf(pdf_path, verbose)
    if not text.strip():
        print(f"  [skip] No text extracted")
        return []

    # Step 2: Transcript preprocessing
    if is_transcript_format(text):
        print(f"  Detected transcript format, preprocessing...")
        text = preprocess_transcript(text)

    # Step 3: Chunk
    chunks = chunk_by_idea(text, verbose)
    print(f"  {len(chunks)} chunks")

    # Step 4+5: Classify + Extract
    results = []
    for i, chunk_text in enumerate(chunks):
        if len(chunk_text.strip()) < 50:
            if verbose:
                print(f"  [skip] Chunk {i+1} too short ({len(chunk_text)} chars)")
            continue

        print(f"  Chunk {i+1}/{len(chunks)}...", end=" ", flush=True)

        topic_slug, role = classify_chunk(chunk_text, provider, verbose)
        print(f"-> {topic_slug} ({role})", end=" ", flush=True)

        entry = extract_from_chunk(
            chunk_text, topic_slug, role, source_ref, provider, verbose
        )

        if entry:
            results.append(entry)
            print("OK")
        else:
            print("[no extraction]")

    print(f"  Extracted {len(results)} entries")
    return results


def process_path(
    input_path: str,
    provider: str,
    source_name: Optional[str],
    verbose: bool,
) -> list:
    """Process a single PDF or all PDFs in a directory."""
    path = Path(input_path)

    if path.is_file() and path.suffix.lower() == ".pdf":
        return process_single_pdf(str(path), provider, source_name, verbose)

    if path.is_dir():
        pdf_files = sorted(path.glob("*.pdf"))
        if not pdf_files:
            print(f"No PDF files found in {input_path}")
            return []

        print(f"Found {len(pdf_files)} PDF files in {input_path}")
        all_entries = []
        for pdf_file in pdf_files:
            entries = process_single_pdf(
                str(pdf_file), provider, source_name, verbose
            )
            all_entries.extend(entries)
        return all_entries

    print(f"Error: {input_path} is not a PDF file or directory")
    sys.exit(1)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def resolve_output_path(args_output: Optional[str]) -> str:
    """Resolve output path, defaulting to project's DefaultKnowledge.json."""
    if args_output:
        return str(Path(args_output).resolve())

    script_dir = Path(__file__).resolve().parent  # scripts/
    project_root = script_dir.parent
    default_path = project_root / DEFAULT_OUTPUT

    if default_path.parent.exists():
        return str(default_path)

    return str(Path.cwd() / "DefaultKnowledge.json")


def main():
    parser = argparse.ArgumentParser(
        description="Extract coaching knowledge from PDFs for BetterOne's DefaultKnowledge.json",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 scripts/process_knowledge.py coaching-guide.pdf
  python3 scripts/process_knowledge.py ./pdfs/ --provider openai --verbose
  python3 scripts/process_knowledge.py transcript.pdf --source-name "YouTube: Life OS" --dry-run
        """,
    )
    parser.add_argument("input", help="Path to a PDF file or directory of PDFs")
    parser.add_argument(
        "--provider", choices=["claude", "openai"], default="claude",
        help="LLM provider (default: claude)",
    )
    parser.add_argument(
        "--output", default=None,
        help=f"Output JSON path (default: <project>/{DEFAULT_OUTPUT})",
    )
    parser.add_argument(
        "--source-name", default=None,
        help="Override sourceReference for all entries (default: PDF filename)",
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Print extracted entries as JSON without writing to file",
    )
    parser.add_argument(
        "--verbose", action="store_true",
        help="Show detailed progress and LLM responses",
    )

    args = parser.parse_args()

    # Validate input
    input_path = Path(args.input).resolve()
    if not input_path.exists():
        print(f"Error: {args.input} does not exist")
        sys.exit(1)

    # Validate API key
    if args.provider == "claude":
        if not os.environ.get("ANTHROPIC_API_KEY"):
            print("Error: ANTHROPIC_API_KEY not set")
            print("  export ANTHROPIC_API_KEY='sk-ant-...'")
            sys.exit(1)
    elif args.provider == "openai":
        if not os.environ.get("OPENAI_API_KEY"):
            print("Error: OPENAI_API_KEY not set")
            print("  export OPENAI_API_KEY='sk-...'")
            sys.exit(1)

    output_path = resolve_output_path(args.output)

    print("BetterOne Knowledge Processor")
    print(f"  Provider: {args.provider}")
    print(f"  Input:    {input_path}")
    print(f"  Output:   {output_path}")
    if args.dry_run:
        print("  Mode:     DRY RUN")
    print()

    # Run pipeline
    new_entries = process_path(
        str(input_path), args.provider, args.source_name, args.verbose
    )

    if not new_entries:
        print("\nNo knowledge entries extracted.")
        sys.exit(0)

    new_dicts = [e.to_dict() for e in new_entries]

    # Summary by topic
    topic_counts = {}
    for d in new_dicts:
        slug = d["topicSlug"]
        topic_counts[slug] = topic_counts.get(slug, 0) + 1
    print(f"\nExtracted {len(new_dicts)} entries:")
    for slug, count in sorted(topic_counts.items()):
        print(f"  {slug}: {count}")

    if args.dry_run:
        print(f"\n--- Dry Run Output ---")
        print(json.dumps(new_dicts, indent=4, ensure_ascii=False))
        return

    # Merge with existing
    existing = load_existing(output_path)
    added = 0
    skipped = 0

    for entry_dict in new_dicts:
        entry_obj = KnowledgeEntry(**entry_dict)
        if is_duplicate(entry_obj, existing):
            skipped += 1
            if args.verbose:
                print(f"  [dup] {entry_dict['coreIdea'][:60]}...")
        else:
            existing.append(entry_dict)
            added += 1

    save_knowledge(existing, output_path)

    print(f"\nDone!")
    print(f"  Added:   {added} new entries")
    print(f"  Skipped: {skipped} duplicates")
    print(f"  Total:   {len(existing)} entries in {output_path}")


if __name__ == "__main__":
    main()
