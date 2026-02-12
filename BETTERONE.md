# BetterOne

### An AI coaching app that helps you think clearer, get organized, and actually follow through.

---

## The Problem

We all want to be more productive, set better goals, and build habits that stick. But most of us get stuck — not because we lack information, but because we lack **guided support at the right moment**.

Here is what that looks like in real life:

- **Sarah** downloads a habit tracker app. She uses it for two weeks, then stops. The app told her *what* to track but never helped her figure out *why* she kept falling off.
- **James** watches 20 YouTube videos about Notion productivity systems. He builds a complicated dashboard, gets overwhelmed, and goes back to sticky notes.
- **Priya** sets a quarterly goal at work but has no one to talk through the messy middle — the part where motivation fades and the plan needs adjusting.

The common thread? **These people don't need another tool. They need a thinking partner.** Someone who listens, asks the right questions, and helps them figure out the next step — on their own terms, on their own schedule.

Professional coaching solves this, but it costs $100-300 per session. Most people can't justify that for everyday productivity questions. And generic AI chatbots (like asking ChatGPT "how do I be more productive?") give broad, impersonal answers with no memory, no structure, and no follow-through.

**The gap:** There is no affordable, structured, always-available coaching experience for personal productivity and life organization.

---

## Who Is This For?

BetterOne is built for **people who are trying to get their life more organized** — but keep getting stuck between knowing what to do and actually doing it.

### Our core users:

| Who they are | What they struggle with | How BetterOne helps |
|---|---|---|
| **Young professionals (22-35)** | Setting goals that don't fizzle out after January | Guided goal-setting sessions that break vague ambitions into clear weekly actions |
| **Freelancers & creators** | Managing clients, content, and personal life without dropping balls | Coaching on building systems (like a Client & Content OS) that fit how they actually work |
| **Students & self-learners** | Information overload — saving everything, finding nothing | Sessions on building a Second Brain and capturing ideas in a way that's actually useful later |
| **Notion users (beginner to advanced)** | Spending more time tweaking their setup than using it | Focused coaching on Notion foundations, templates, and workflows — from scratch to advanced |
| **Anyone feeling stuck** | Knowing they *should* be more organized but not knowing where to start | A low-pressure conversation that starts with "What would make this useful?" — not a 47-step tutorial |

### What makes our audience unique:

These are **action-oriented people**. They're already searching for solutions — downloading apps, watching tutorials, buying courses. They don't lack motivation. They lack a **conversation partner** who meets them where they are and helps them move forward one step at a time.

---

## Our Solution

BetterOne pairs you with **Simon**, an AI coach with a defined personality, coaching style, and set of boundaries — not a generic chatbot.

### How a session works (with examples):

**Step 1: Pick a topic.**
You choose from areas like *Goal Setting*, *Habit Tracking*, *Notion Life OS*, or *Productivity Principles*. Each topic has its own knowledge base, so Simon's advice is grounded in real frameworks — not just general AI output.

**Step 2: Set your intent.**
Before the conversation starts, BetterOne asks: *"What would make this useful?"* You pick one:
- **Clarity** — "I want to see things more clearly"
- **Direction** — "I need help choosing a path"
- **A next step** — "I want something concrete to do"
- **Thinking out loud** — "I just need space to process"

This means two people picking the same topic can have completely different conversations. Someone choosing "Clarity" on Goal Setting might explore *why* their goals keep failing. Someone choosing "A next step" gets a specific action they can do today.

**Step 3: Have a real conversation.**
Simon doesn't lecture. He asks questions, reflects back what you said, and offers one idea at a time. For example:

> **You:** I want to start tracking my habits but I always quit after a week.
>
> **Simon:** That's really common — and the fact that you keep trying says something good. What usually happens around day 5 or 6 that makes it feel not worth it?

The conversation is guided by safety rules: Simon won't diagnose mental health conditions, give financial advice, or pressure you into decisions. He stays in his lane.

**Step 4: Get your takeaway.**
When you end the session, BetterOne generates a personalized **takeaway** (the key insight) and a **next step** (one concrete action). These are saved in your history so you can revisit them.

**Step 5: Stay engaged between sessions.**
A Home Screen widget shows a daily coaching tip — pulled from the app's knowledge base or your own past session insights. It keeps the momentum going without requiring you to open the app.

---

## How We Make Money

BetterOne uses a **freemium model** — free users get real value, and premium users get access to everything.

### Free Tier (always free):
- Unlimited coaching sessions across **7 core topics** (Goal Setting, Habit Tracking, Notion Life OS, Simplified Life OS, Notion Foundations, Productivity Principles, Design Workspace)
- Full conversation history
- Daily coaching tip widget
- Session takeaways and next steps

### Premium Tier (monthly or yearly subscription):
- Everything in Free, plus...
- **5 additional premium topics**: Second Brain & Knowledge Management, Client & Content OS, Task & Project Management, AI & Notion AgentOS Framework, Information Organization & Idea Capture
- Priority AI responses

### Why this works:

1. **Free users aren't limited — they're invested.** By giving unlimited sessions on core topics, users build a real habit of using BetterOne. They experience the coaching quality firsthand. When they see a premium topic that matches their need (like "Client & Content OS" for a freelancer), the upgrade feels natural — not forced.

2. **The paywall is about depth, not access.** We never cut someone off mid-conversation or limit sessions. Premium unlocks *more specialized topics* for people who want to go deeper. This feels fair and avoids the frustration of hitting arbitrary limits.

3. **Subscription revenue is predictable.** Monthly and yearly plans through the App Store (managed via RevenueCat) give us recurring revenue. A yearly plan at a discount encourages long-term commitment.

### Revenue projections (example):

| Scenario | Free users | Conversion rate | Premium price | Monthly revenue |
|---|---|---|---|---|
| **Conservative** | 5,000 | 3% | $4.99/mo | $749 |
| **Moderate** | 25,000 | 5% | $4.99/mo | $6,237 |
| **Growth** | 100,000 | 7% | $4.99/mo | $34,930 |

These conversion rates are realistic for productivity apps with a strong free tier (industry average for freemium apps is 2-5%).

### Future monetization opportunities:
- **Creator partnerships:** Other coaches and experts could create their own personas and topic packs, sold as in-app purchases — turning BetterOne into a platform.
- **Team/enterprise plans:** Productivity coaching for small teams, with shared topic libraries and manager dashboards.
- **One-time topic packs:** Specialized deep-dive topics (e.g., "Launch Your Side Project" or "ADHD-Friendly Productivity") sold individually.

---

## What Makes BetterOne Different

| Feature | Generic AI chatbot | Traditional coaching | BetterOne |
|---|---|---|---|
| Always available | Yes | No (scheduled sessions) | Yes |
| Personalized to you | No (no memory) | Yes | Yes (remembers your profile & history) |
| Structured sessions | No (open-ended) | Yes | Yes (intent-driven, topic-focused) |
| Safety guardrails | No | Yes (human judgment) | Yes (rule-based + AI safety layer) |
| Affordable | Free but shallow | $100-300/session | Free core + affordable premium |
| Actionable outcomes | Rarely | Usually | Always (takeaway + next step) |

---

## Built With

- **SwiftUI** — native iOS app with a polished, accessible interface
- **SwiftData** — on-device persistence for conversations, topics, and user profiles
- **Multi-LLM support** — works with OpenAI, Claude, and Gemini (provider-agnostic)
- **RevenueCat** — subscription management and in-app purchases
- **WidgetKit** — daily coaching tip on the Home Screen
- **6-layer prompt architecture** — rules, persona, topic context, user profile, knowledge base, and response instructions are composed into every AI interaction

---

*BetterOne — because getting better at life shouldn't require a $200/hour coach.*
