import Foundation

struct LLMConfiguration: Codable, Sendable {
    enum Provider: String, Codable, CaseIterable, Sendable {
        case openai
        case gemini
        case claude
    }

    var provider: Provider
    var apiKey: String
    var model: String
    var temperature: Double
    var maxTokens: Int

    private static var defaultAPIKey: String {
        Bundle.main.object(forInfoDictionaryKey: "LLM_API_KEY") as? String ?? ""
    }

    static let defaultOpenAI = LLMConfiguration(
        provider: .openai, apiKey: defaultAPIKey, model: "gpt-4o",
        temperature: 0.7, maxTokens: 1024
    )

    static let defaultClaude = LLMConfiguration(
        provider: .claude, apiKey: defaultAPIKey, model: "claude-sonnet-4-20250514",
        temperature: 0.7, maxTokens: 1024
    )

    static let defaultGemini = LLMConfiguration(
        provider: .gemini, apiKey: defaultAPIKey, model: "gemini-flash-latest",
        temperature: 0.7, maxTokens: 1024
    )
}
