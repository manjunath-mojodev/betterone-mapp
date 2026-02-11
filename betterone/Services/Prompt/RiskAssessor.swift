import Foundation

struct RiskAssessment {
    let isFlagged: Bool
    let triggerType: String?
    let matchedRule: Rule?
    let explanation: String?

    static let safe = RiskAssessment(isFlagged: false, triggerType: nil, matchedRule: nil, explanation: nil)
}

struct RiskAssessor {
    let rules: [Rule]

    // MARK: - Combined Assessment (rules first, LLM fallback)

    func assess(userMessage: String, llmService: LLMService?) async -> RiskAssessment {
        // Step 1: Rules-based check (fast, no API call)
        if let ruleResult = assessRuleBased(userMessage: userMessage) {
            return ruleResult
        }

        // Step 2: LLM fallback (only if service is available and configured)
        if let llmService, llmService.isConfigured {
            if let llmResult = await assessWithLLM(userMessage: userMessage, llmService: llmService) {
                return llmResult
            }
        }

        return .safe
    }

    // MARK: - Rules-Based Assessment

    func assessRuleBased(userMessage: String) -> RiskAssessment? {
        let lowercased = userMessage.lowercased()

        let activeRules = rules.filter(\.isActive)

        for rule in activeRules {
            let keywords = keywordsForRule(rule)
            for keyword in keywords {
                if lowercased.contains(keyword) {
                    return RiskAssessment(
                        isFlagged: true,
                        triggerType: "rule_based",
                        matchedRule: rule,
                        explanation: "Message contains '\(keyword)' which may approach the boundary: \(rule.title)"
                    )
                }
            }
        }

        return nil
    }

    // MARK: - LLM-Based Assessment

    func assessWithLLM(userMessage: String, llmService: LLMService) async -> RiskAssessment? {
        let prompt = """
            You are a safety classifier for an AI coaching system. Analyze the following user message and determine if it approaches any of these boundaries:

            BOUNDARIES:
            \(rules.filter(\.isActive).map { "- \($0.title): \($0.content)" }.joined(separator: "\n"))

            USER MESSAGE:
            \(userMessage)

            Respond with EXACTLY one of:
            SAFE - if the message does not approach any boundary
            FLAGGED|<rule_title>|<brief_explanation> - if it does

            Examples:
            SAFE
            FLAGGED|No mental health diagnosis|User appears to be describing symptoms of depression and seeking diagnosis
            """

        let messages = [
            LLMMessage(role: "system", content: "You are a concise safety classifier. Respond in the exact format specified."),
            LLMMessage(role: "user", content: prompt)
        ]

        do {
            let response = try await llmService.complete(messages: messages)
            return parseLLMAssessment(response)
        } catch {
            // If LLM assessment fails, don't block the conversation
            return nil
        }
    }

    // MARK: - Private Helpers

    private func parseLLMAssessment(_ response: String) -> RiskAssessment? {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.uppercased().hasPrefix("SAFE") {
            return nil // not flagged
        }

        if trimmed.uppercased().hasPrefix("FLAGGED") {
            let parts = trimmed.components(separatedBy: "|")
            let ruleTitle = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : nil
            let explanation = parts.count > 2 ? parts[2].trimmingCharacters(in: .whitespaces) : nil

            let matchedRule = ruleTitle.flatMap { title in
                rules.first { $0.title.lowercased() == title.lowercased() }
            }

            return RiskAssessment(
                isFlagged: true,
                triggerType: "llm_detected",
                matchedRule: matchedRule,
                explanation: explanation
            )
        }

        return nil
    }

    private func keywordsForRule(_ rule: Rule) -> [String] {
        switch rule.category {
        case "boundary":
            return boundaryKeywords(for: rule)
        case "scope":
            return [] // scope violations are contextual, handled by LLM
        default:
            return [] // behavior/tone rules don't trigger on keywords
        }
    }

    private func boundaryKeywords(for rule: Rule) -> [String] {
        let title = rule.title.lowercased()

        if title.contains("mental health") || title.contains("diagnos") {
            return [
                "diagnose me", "am i depressed", "do i have anxiety", "do i have adhd",
                "mental illness", "psychiatric", "bipolar", "schizophreni",
                "suicid", "self-harm", "kill myself", "end my life", "want to die"
            ]
        }

        if title.contains("financial") || title.contains("legal") {
            return [
                "should i invest", "stock pick", "tax advice", "legal advice",
                "sue", "lawyer", "lawsuit", "which stocks", "crypto invest",
                "financial plan", "retirement fund"
            ]
        }

        if title.contains("certainty") || title.contains("guarantee") {
            return [
                "guarantee", "promise me", "100%", "will definitely",
                "can you assure", "is it certain"
            ]
        }

        return []
    }
}
