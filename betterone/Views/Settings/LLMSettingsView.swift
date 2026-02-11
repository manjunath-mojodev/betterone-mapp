import SwiftUI

struct LLMSettingsView: View {
    @Environment(LLMService.self) private var llmService

    var body: some View {
        @Bindable var service = llmService

        Form {
            Section("Provider") {
                Picker("Provider", selection: $service.configuration.provider) {
                    Text("OpenAI").tag(LLMConfiguration.Provider.openai)
                    Text("Claude").tag(LLMConfiguration.Provider.claude)
                    Text("Gemini").tag(LLMConfiguration.Provider.gemini)
                }
                .pickerStyle(.segmented)
            }

            Section("API Key") {
                SecureField("Enter API key", text: $service.configuration.apiKey)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .accessibilityLabel("API key for \(service.configuration.provider.rawValue)")

                if service.isConfigured {
                    Label("Key configured", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Theme.success)
                        .font(Theme.captionFont)
                } else {
                    Label("No API key set", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(Theme.warning)
                        .font(Theme.captionFont)
                }
            }

            Section("Model") {
                TextField("Model name", text: $service.configuration.model)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Model name")
                    .accessibilityHint("Currently: \(service.configuration.model)")

                Text(defaultModelHint)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textSecondary)
            }

            Section("Parameters") {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    HStack {
                        Text("Temperature")
                        Spacer()
                        Text(String(format: "%.1f", service.configuration.temperature))
                            .foregroundStyle(Theme.textSecondary)
                            .monospacedDigit()
                    }
                    Slider(value: $service.configuration.temperature, in: 0...1, step: 0.1)
                        .accessibilityLabel("Temperature")
                        .accessibilityValue(String(format: "%.1f", service.configuration.temperature))
                }

                Stepper("Max tokens: \(service.configuration.maxTokens)",
                        value: $service.configuration.maxTokens, in: 256...4096, step: 256)
                    .accessibilityLabel("Maximum tokens")
                    .accessibilityValue("\(service.configuration.maxTokens)")
            }
        }
        .navigationTitle("LLM Provider")
        .onChange(of: service.configuration.provider) {
            switch service.configuration.provider {
            case .openai:
                service.configuration.model = LLMConfiguration.defaultOpenAI.model
            case .claude:
                service.configuration.model = LLMConfiguration.defaultClaude.model
            case .gemini:
                service.configuration.model = LLMConfiguration.defaultGemini.model
            }
        }
    }

    private var defaultModelHint: String {
        switch llmService.configuration.provider {
        case .openai: "Default: gpt-4o"
        case .claude: "Default: claude-sonnet-4-20250514"
        case .gemini: "Default: gemini-2.0-flash"
        }
    }
}
