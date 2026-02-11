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

    private static var bundledConfig: [String: Any]? {
        guard let url = Bundle.main.url(forResource: "LLMConfig", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return nil }
        return dict
    }

    static var bundledAPIKey: String {
        Secrets.llmAPIKey
    }

    static var bundledProvider: Provider {
        if let raw = bundledConfig?["LLM_PROVIDER"] as? String,
           let provider = Provider(rawValue: raw) {
            return provider
        }
        return .openai
    }

    static let defaultOpenAI = LLMConfiguration(
        provider: .openai, apiKey: bundledAPIKey, model: "gpt-4o",
        temperature: 0.7, maxTokens: 1024
    )

    static let defaultClaude = LLMConfiguration(
        provider: .claude, apiKey: bundledAPIKey, model: "claude-sonnet-4-20250514",
        temperature: 0.7, maxTokens: 1024
    )

    static let defaultGemini = LLMConfiguration(
        provider: .gemini, apiKey: bundledAPIKey, model: "gemini-flash-latest",
        temperature: 0.7, maxTokens: 1024
    )

    static var bundledDefault: LLMConfiguration {
        switch bundledProvider {
        case .openai: return defaultOpenAI
        case .claude: return defaultClaude
        case .gemini: return defaultGemini
        }
    }
}
