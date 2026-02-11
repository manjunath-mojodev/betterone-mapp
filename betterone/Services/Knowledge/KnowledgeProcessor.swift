import Foundation
import SwiftData

final class KnowledgeProcessor {
    private let llmService: LLMService
    private let topicSlugs = [
        "notion-life-os", "simplified-life-os", "second-brain", "client-content-os",
        "goal-setting", "habit-tracking", "task-project-management", "ai-agent-os",
        "notion-foundations", "productivity-principles", "info-org-capture", "design-workspace"
    ]

    init(llmService: LLMService) {
        self.llmService = llmService
    }

    // MARK: - Chunk by Idea

    func chunkByIdea(text: String) -> [String] {
        let lines = text.components(separatedBy: "\n")
        var chunks: [String] = []
        var currentChunk: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Start a new chunk on headings or after significant whitespace
            let isHeading = trimmed.hasPrefix("# ") || trimmed.hasPrefix("## ") || trimmed.hasPrefix("### ")
            let isEmpty = trimmed.isEmpty

            if isHeading && !currentChunk.isEmpty {
                chunks.append(currentChunk.joined(separator: "\n"))
                currentChunk = [line]
            } else if isEmpty && currentChunk.count > 3 {
                // Paragraph break with enough content — split here
                chunks.append(currentChunk.joined(separator: "\n"))
                currentChunk = []
            } else if !isEmpty {
                currentChunk.append(line)
            }
        }

        if !currentChunk.isEmpty {
            chunks.append(currentChunk.joined(separator: "\n"))
        }

        // Merge very small chunks with the next one
        var merged: [String] = []
        for chunk in chunks {
            if let last = merged.last, last.count < 100 {
                merged[merged.count - 1] = last + "\n" + chunk
            } else {
                merged.append(chunk)
            }
        }

        return merged
    }

    // MARK: - Step 3: Classify

    func classify(chunk: String) async -> (topicSlug: String, role: String) {
        guard llmService.isConfigured else {
            return ("productivity-principles", "knowledge")
        }

        let prompt = """
            Classify the following text chunk from a coaching knowledge base.

            TEXT:
            \(chunk.truncated(to: 1000))

            Respond with EXACTLY two lines:
            TOPIC: <one of: notion-life-os, simplified-life-os, second-brain, client-content-os, goal-setting, habit-tracking, task-project-management, ai-agent-os, notion-foundations, productivity-principles, info-org-capture, design-workspace>
            ROLE: <one of: knowledge, persona_signal, boundary_risk>

            Topic guide:
            - notion-life-os: Comprehensive Notion life operating system
            - simplified-life-os: Beginner-friendly simplified Notion setup
            - second-brain: Knowledge management, capturing and retrieving ideas
            - client-content-os: Client management, content pipelines, freelancing
            - goal-setting: Goals, planning, yearly reviews
            - habit-tracking: Habits, consistency, routine building
            - task-project-management: Tasks, projects, priorities, dashboards
            - ai-agent-os: AI agents, prompt engineering, agent design
            - notion-foundations: Notion basics, databases, relations, formulas
            - productivity-principles: Productivity philosophy, workflows, essentialism
            - info-org-capture: Information organization, idea capture systems
            - design-workspace: Notion aesthetics, dashboard design, visual layout

            Role definitions:
            - knowledge: Coaching frameworks, advice, methods, strategies
            - persona_signal: Indicators of the creator's voice, tone, beliefs, style
            - boundary_risk: Content about limitations, what not to do, safety concerns
            """

        let messages = [
            LLMMessage(role: "system", content: "You are a concise text classifier. Respond in the exact format specified."),
            LLMMessage(role: "user", content: prompt)
        ]

        do {
            let response = try await llmService.complete(messages: messages)
            return parseClassification(response)
        } catch {
            return ("productivity-principles", "knowledge")
        }
    }

    // MARK: - Step 4: Extract Knowledge Object

    func extractKnowledgeObject(
        chunk: String,
        classification: (topicSlug: String, role: String),
        sourceTitle: String
    ) async -> KnowledgeObject? {
        guard llmService.isConfigured else {
            return KnowledgeObject(
                coreIdea: chunk.truncated(to: 200),
                whenToUse: "General coaching context",
                heuristics: [],
                whatToAvoid: [],
                sourceReference: sourceTitle,
                role: classification.role
            )
        }

        let prompt = """
            Extract a structured coaching knowledge object from the following text.

            TEXT:
            \(chunk.truncated(to: 1500))

            Respond in this exact format (each field on its own line):
            CORE_IDEA: <one sentence summarizing the main coaching insight>
            WHEN_TO_USE: <when a coach should apply this idea>
            HEURISTICS: <2-3 practical guidelines, separated by |>
            WHAT_TO_AVOID: <1-2 things to avoid, separated by |>

            Be concise. Each field should be 1-2 sentences max.
            """

        let messages = [
            LLMMessage(role: "system", content: "You are a knowledge extraction specialist. Respond in the exact format specified."),
            LLMMessage(role: "user", content: prompt)
        ]

        do {
            let response = try await llmService.complete(messages: messages)
            return parseKnowledgeObject(response, classification: classification, sourceTitle: sourceTitle)
        } catch {
            return nil
        }
    }

    // MARK: - Parsing Helpers

    private func parseClassification(_ response: String) -> (topicSlug: String, role: String) {
        var topicSlug = "productivity-principles"
        var role = "knowledge"

        for line in response.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.uppercased().hasPrefix("TOPIC:") {
                let value = String(trimmed.dropFirst("TOPIC:".count)).trimmingCharacters(in: .whitespaces).lowercased()
                if topicSlugs.contains(value) {
                    topicSlug = value
                }
            } else if trimmed.uppercased().hasPrefix("ROLE:") {
                let value = String(trimmed.dropFirst("ROLE:".count)).trimmingCharacters(in: .whitespaces).lowercased()
                if ["knowledge", "persona_signal", "boundary_risk"].contains(value) {
                    role = value
                }
            }
        }

        return (topicSlug, role)
    }

    private func parseKnowledgeObject(
        _ response: String,
        classification: (topicSlug: String, role: String),
        sourceTitle: String
    ) -> KnowledgeObject? {
        var coreIdea = ""
        var whenToUse = ""
        var heuristics: [String] = []
        var whatToAvoid: [String] = []

        for line in response.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.uppercased().hasPrefix("CORE_IDEA:") {
                coreIdea = String(trimmed.dropFirst("CORE_IDEA:".count)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.uppercased().hasPrefix("WHEN_TO_USE:") {
                whenToUse = String(trimmed.dropFirst("WHEN_TO_USE:".count)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.uppercased().hasPrefix("HEURISTICS:") {
                let value = String(trimmed.dropFirst("HEURISTICS:".count)).trimmingCharacters(in: .whitespaces)
                heuristics = value.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            } else if trimmed.uppercased().hasPrefix("WHAT_TO_AVOID:") {
                let value = String(trimmed.dropFirst("WHAT_TO_AVOID:".count)).trimmingCharacters(in: .whitespaces)
                whatToAvoid = value.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            }
        }

        guard !coreIdea.isEmpty else { return nil }

        let ko = KnowledgeObject(
            coreIdea: coreIdea,
            whenToUse: whenToUse,
            heuristics: heuristics,
            whatToAvoid: whatToAvoid,
            sourceReference: sourceTitle,
            role: classification.role
        )
        return ko
    }
}
