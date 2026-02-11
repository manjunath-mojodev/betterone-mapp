import Foundation

@Observable
final class LLMService {
    var configuration: LLMConfiguration {
        didSet { saveConfiguration() }
    }

    init() {
        self.configuration = Self.loadConfiguration()
    }

    private var provider: any LLMProvider {
        switch configuration.provider {
        case .openai: OpenAIProvider()
        case .claude: ClaudeProvider()
        case .gemini: GeminiProvider()
        }
    }

    var isConfigured: Bool {
        !configuration.apiKey.isEmpty
    }

    func complete(messages: [LLMMessage]) async throws -> String {
        try await provider.sendMessage(messages: messages, config: configuration)
    }

    func stream(messages: [LLMMessage]) -> AsyncThrowingStream<String, Error> {
        let currentProvider = provider
        let currentConfig = configuration
        return currentProvider.streamMessage(messages: messages, config: currentConfig)
    }

    // MARK: - Persistence

    private func saveConfiguration() {
        if let data = try? JSONEncoder().encode(configuration) {
            UserDefaults.standard.set(data, forKey: "llmConfiguration")
        }
    }

    private static func loadConfiguration() -> LLMConfiguration {
        // Always use bundled config — provider settings are not user-editable.
        return .bundledDefault
    }
}
