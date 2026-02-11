import Foundation

struct PromptBuilder {
    let persona: PersonaIdentity
    let rules: [Rule]
    let topic: Topic
    let intent: String
    let followerProfile: FollowerProfile?
    let knowledgeObjects: [KnowledgeObject]
    let conversationHistory: [ChatMessage]
    let isFirstMessage: Bool
    var riskAssessment: RiskAssessment? = nil

    func build() -> [LLMMessage] {
        let systemPrompt = buildSystemPrompt()
        var messages = [LLMMessage(role: "system", content: systemPrompt)]

        for message in conversationHistory {
            messages.append(LLMMessage(role: message.role, content: message.content))
        }

        if isFirstMessage {
            messages.append(LLMMessage(role: "user", content: "[Session started. Generate your opening message.]"))
        }

        return messages
    }

    func buildSystemPrompt() -> String {
        var sections: [String] = []

        // Layer 1: Rules of Engagement (HIGHEST PRIORITY)
        sections.append(buildRulesSection())

        // Layer 2: Persona Identity
        sections.append(buildPersonaSection())

        // Layer 3: Topic Context + Session Intent
        sections.append(buildTopicSection())

        // Layer 4: Follower Profile (framing only)
        if let profile = followerProfile {
            sections.append(buildFollowerSection(profile))
        }

        // Layer 5: Knowledge Base
        sections.append(buildKnowledgeSection())

        // Layer 6: Response Instructions
        sections.append(buildResponseSection())

        return sections.joined(separator: "\n\n")
    }

    // MARK: - Layer Builders

    private func buildRulesSection() -> String {
        var section = PromptTemplates.rulesHeader + "\n"

        let activeRules = rules.filter(\.isActive).sorted { $0.priority < $1.priority }

        if activeRules.isEmpty {
            section += "\n(No specific rules configured. Use good judgment and coaching best practices.)"
        } else {
            for rule in activeRules {
                section += "\n- [\(rule.category.uppercased())] \(rule.title): \(rule.content)"
            }
        }

        return section
    }

    private func buildPersonaSection() -> String {
        """
        \(PromptTemplates.personaHeader)

        Name: \(persona.name)
        Voice: \(persona.voice)
        Tone: \(persona.tone)
        Coaching Style: \(persona.coachingStyle)
        Core Beliefs:
        \(persona.coreBeliefs.map { "- \($0)" }.joined(separator: "\n"))
        Risk Stance: \(persona.riskStance)
        Boundaries:
        \(persona.boundaries.map { "- \($0)" }.joined(separator: "\n"))
        """
    }

    private func buildTopicSection() -> String {
        let intentLabel = intentDisplayName(intent)

        return """
        \(PromptTemplates.topicHeader)

        Topic: \(topic.title)
        Topic Framing: \(topic.subtitle)
        Session Intent: The user wants "\(intentLabel)" from this conversation.
        Scope: Stay within \(topic.title). If the user drifts to another topic, gently acknowledge and redirect.
        """
    }

    private func buildFollowerSection(_ profile: FollowerProfile) -> String {
        let feedbackLabel = profile.feedbackStyle == "gentle" ? "Gentle & reflective" : "Direct & practical"
        let areas = profile.helpAreas.joined(separator: ", ")

        var section = """
        \(PromptTemplates.followerHeader)

        Focus Areas: \(areas.isEmpty ? "Not specified" : areas)
        Preferred Feedback Style: \(feedbackLabel)
        """

        if let note = profile.optionalNote, !note.isEmpty {
            section += "\nAdditional Context: \(note)"
        }

        return section
    }

    private func buildKnowledgeSection() -> String {
        var section = PromptTemplates.knowledgeHeader + "\n"

        if knowledgeObjects.isEmpty {
            section += """

            (No specific knowledge items available for this topic.)
            Rely on the persona's core beliefs and coaching style to guide your responses.
            Be honest if you don't have a specific framework — reason from first principles.
            """
        } else {
            for (index, ko) in knowledgeObjects.prefix(3).enumerated() {
                section += """

                Idea \(index + 1):
                  Core Idea: \(ko.coreIdea)
                  When to Use: \(ko.whenToUse)
                  Guiding Heuristics: \(ko.heuristics.joined(separator: "; "))
                  What to Avoid: \(ko.whatToAvoid.joined(separator: "; "))
                  Source: \(ko.sourceReference)
                """
            }
        }

        return section
    }

    private func buildResponseSection() -> String {
        var section = PromptTemplates.responseHeader + "\n"
        section += PromptTemplates.responseInstructions

        if isFirstMessage {
            section += "\n\n" + PromptTemplates.firstMessageInstruction
        }

        if let risk = riskAssessment, risk.isFlagged {
            section += """


            === RISK ALERT (active for this response) ===
            The user's latest message has been flagged by the safety system.
            Trigger: \(risk.triggerType ?? "unknown") — \(risk.matchedRule?.title ?? "General boundary")
            Reason: \(risk.explanation ?? "Potential boundary approach detected")

            YOU MUST:
            - Acknowledge the user's concern with empathy
            - Transparently explain that this falls outside your coaching scope
            - If appropriate, suggest they speak to a qualified professional
            - Do NOT provide advice on the flagged topic
            - Keep your response warm and supportive, not robotic or dismissive
            """
        }

        return section
    }

    // MARK: - Helpers

    private func intentDisplayName(_ intent: String) -> String {
        switch intent {
        case "clarity": return "Clarity — seeing things more clearly"
        case "direction": return "Direction — help choosing a path"
        case "next_step": return "A concrete next step"
        case "thinking_out_loud": return "Space to think out loud"
        default: return intent
        }
    }
}
