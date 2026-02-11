import SwiftUI
import SwiftData

struct ResponseSandboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LLMService.self) private var llmService
    @Query(sort: \Topic.sortOrder) private var topics: [Topic]
    @Query private var personas: [PersonaIdentity]
    @Query(sort: \Rule.priority) private var rules: [Rule]
    @Query private var profiles: [FollowerProfile]

    @State private var selectedTopic: Topic?
    @State private var selectedIntent = "clarity"
    @State private var testMessage = ""
    @State private var response = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPromptInspector = false
    @State private var assembledPrompt = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingMD) {
                Text("Test how the AI coach responds with the full prompt stack.")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textSecondary)

                // Topic picker
                VStack(alignment: .leading, spacing: Theme.spacingSM) {
                    Text("Topic")
                        .font(Theme.headlineFont)

                    if topics.isEmpty {
                        Text("No topics available. Topics load on first launch.")
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.spacingSM) {
                                ForEach(topics) { topic in
                                    PillButton(
                                        title: topic.title,
                                        isSelected: selectedTopic?.id == topic.id
                                    ) {
                                        selectedTopic = topic
                                    }
                                }
                            }
                        }
                    }
                }

                // Intent picker
                VStack(alignment: .leading, spacing: Theme.spacingSM) {
                    Text("Session Intent")
                        .font(Theme.headlineFont)
                    Picker("Intent", selection: $selectedIntent) {
                        ForEach(AppConstants.sessionIntents) { intent in
                            Text(intent.title).tag(intent.id)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Test message
                TextField("Enter a test message...", text: $testMessage, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.send)
                    .accessibilityLabel("Test message")

                // Actions
                HStack(spacing: Theme.spacingSM) {
                    Button("Send Test") {
                        sendTest()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSend)

                    Button("Inspect Prompt") {
                        inspectPrompt()
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedTopic == nil)

                    if isLoading {
                        ProgressView()
                            .accessibilityLabel("Generating response")
                    }
                }

                if !llmService.isConfigured {
                    Label("Configure an API key in Settings > LLM Provider first.", systemImage: "exclamationmark.triangle")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.warning)
                }

                if let errorMessage {
                    HStack(spacing: Theme.spacingSM) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.error)
                        Text(errorMessage)
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                // Response
                if !response.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.spacingSM) {
                        Text("Response")
                            .font(Theme.headlineFont)
                        Text(response)
                            .font(Theme.bodyFont)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Theme.spacingMD)
                            .background(Theme.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                            .textSelection(.enabled)
                    }
                }
            }
            .padding(Theme.spacingMD)
        }
        .navigationTitle("Response Sandbox")
        .onAppear {
            if selectedTopic == nil { selectedTopic = topics.first }
        }
        .sheet(isPresented: $showPromptInspector) {
            NavigationStack {
                ScrollView {
                    Text(assembledPrompt)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .textSelection(.enabled)
                }
                .navigationTitle("Assembled Prompt")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showPromptInspector = false }
                    }
                }
            }
        }
    }

    private var canSend: Bool {
        !testMessage.isEmpty && !isLoading && llmService.isConfigured && selectedTopic != nil
    }

    private func buildPrompt(isFirstMessage: Bool) -> PromptBuilder? {
        guard let topic = selectedTopic, let persona = personas.first else { return nil }

        let knowledgeDescriptor = FetchDescriptor<KnowledgeObject>()
        let allKnowledge = (try? modelContext.fetch(knowledgeDescriptor)) ?? []
        let knowledge = allKnowledge.filter { $0.topic?.slug == topic.slug }

        return PromptBuilder(
            persona: persona,
            rules: rules,
            topic: topic,
            intent: selectedIntent,
            followerProfile: profiles.first,
            knowledgeObjects: Array(knowledge.prefix(3)),
            conversationHistory: [],
            isFirstMessage: isFirstMessage
        )
    }

    private func inspectPrompt() {
        guard let builder = buildPrompt(isFirstMessage: false) else { return }
        assembledPrompt = builder.buildSystemPrompt()
        showPromptInspector = true
    }

    private func sendTest() {
        guard let builder = buildPrompt(isFirstMessage: false) else { return }

        isLoading = true
        response = ""
        errorMessage = nil

        Task {
            do {
                var messages = builder.build()
                messages.append(LLMMessage(role: "user", content: testMessage))

                var accumulated = ""
                for try await chunk in llmService.stream(messages: messages) {
                    accumulated += chunk
                    response = accumulated
                }
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
