import SwiftUI
import SwiftData
import WidgetKit

@MainActor
@Observable
final class ChatViewModel {
    let topic: Topic
    private(set) var intent: SessionIntent?
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isStreaming: Bool = false
    var showWrapUp: Bool = false
    var sessionTakeaway: String?
    var sessionNextStep: String?
    var errorMessage: String?

    private var session: ChatSession?
    private var streamingTask: Task<Void, Never>?
    private var activeURLTask: URLSessionTask?
    private var requestGeneration: Int = 0

    let greeting: String

    var hasSelectedIntent: Bool { intent != nil }

    private static let greetingTemplates = [
        "Hey — glad you're here. Let's talk about %@.",
        "Welcome back. Ready to dig into %@?",
        "Good to see you. Let's work through %@ together.",
        "Hey — let's jump into %@.",
        "Alright, %@ it is. Let's get into it.",
    ]

    init(topic: Topic, intent: SessionIntent? = nil) {
        self.topic = topic
        self.intent = intent
        let template = Self.greetingTemplates.randomElement()!
        self.greeting = String(format: template, topic.title.lowercased())
    }

    func selectIntent(_ intent: SessionIntent, modelContext: ModelContext, llmService: LLMService) {
        self.intent = intent

        // Create session
        let session = ChatSession(intent: intent.id)
        session.topic = topic
        modelContext.insert(session)
        self.session = session

        // Persist the greeting as an assistant message
        appendAssistantMessage(
            "\(greeting)\n\nWhat would make this useful?",
            modelContext: modelContext
        )

        // Persist the user's selection as a user message
        let userMessage = ChatMessage(role: "user", content: intent.title)
        userMessage.session = session
        modelContext.insert(userMessage)
        messages.append(userMessage)

        // Generate the LLM response
        generateResponse(userMessage: userMessage, modelContext: modelContext, llmService: llmService)
    }

    // MARK: - Session Lifecycle

    func startSession(modelContext: ModelContext, llmService: LLMService) {
        let session = ChatSession(intent: intent?.id ?? "general")
        session.topic = topic
        modelContext.insert(session)
        self.session = session

        generateOpener(modelContext: modelContext, llmService: llmService)
    }

    func sendMessage(modelContext: ModelContext, llmService: LLMService) {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let userMessage = ChatMessage(role: "user", content: text)
        userMessage.session = session
        modelContext.insert(userMessage)
        messages.append(userMessage)
        inputText = ""

        generateResponse(userMessage: userMessage, modelContext: modelContext, llmService: llmService)
    }

    func endSession(modelContext: ModelContext, llmService: LLMService) {
        activeURLTask?.cancel()
        streamingTask?.cancel()
        session?.endedAt = Date()

        guard messages.count >= 2 else {
            sessionTakeaway = "Every conversation starts somewhere."
            sessionNextStep = "Come back when you're ready to dig in."
            session?.takeaway = sessionTakeaway
            session?.nextStep = sessionNextStep
            showWrapUp = true
            CoachingTipService.refreshTip(modelContext: modelContext)
            return
        }

        generateWrapUp(modelContext: modelContext, llmService: llmService)
    }

    // MARK: - LLM Integration

    private func generateOpener(modelContext: ModelContext, llmService: LLMService) {
        guard llmService.isConfigured else {
            appendAssistantMessage(
                "Hey — glad you're here. Let's talk about \(topic.title.lowercased()). What's on your mind?",
                modelContext: modelContext
            )
            return
        }

        let builder = makePromptBuilder(modelContext: modelContext, isFirstMessage: true)
        let llmMessages = builder.build()

        fetchResponse(
            llmMessages: llmMessages,
            llmService: llmService,
            modelContext: modelContext,
            riskAssessment: nil,
            userMessage: nil
        )
    }

    private func generateResponse(userMessage: ChatMessage, modelContext: ModelContext, llmService: LLMService) {
        guard llmService.isConfigured else {
            appendAssistantMessage(
                "I hear you. (Configure an LLM provider in Settings to enable real responses.)",
                modelContext: modelContext
            )
            return
        }

        // Fast rule-based risk check (no API call)
        let rules = fetchRules(modelContext: modelContext)
        let assessor = RiskAssessor(rules: rules)
        let ruleAssessment = assessor.assessRuleBased(userMessage: userMessage.content) ?? .safe

        if ruleAssessment.isFlagged {
            userMessage.riskFlagged = true
        }

        let builder = makePromptBuilder(
            modelContext: modelContext,
            isFirstMessage: false,
            riskAssessment: ruleAssessment
        )
        var llmMessages = builder.build()
        llmMessages.append(LLMMessage(role: "user", content: userMessage.content))

        fetchResponse(
            llmMessages: llmMessages,
            llmService: llmService,
            modelContext: modelContext,
            riskAssessment: ruleAssessment,
            userMessage: userMessage
        )
    }

    private func generateWrapUp(modelContext: ModelContext, llmService: LLMService) {
        guard llmService.isConfigured else {
            sessionTakeaway = "You're thinking about this the right way."
            sessionNextStep = "Try writing down the one thing that matters most this week."
            session?.takeaway = sessionTakeaway
            session?.nextStep = sessionNextStep
            showWrapUp = true
            return
        }

        let provider = Self.makeProvider(for: llmService.configuration)
        let config = llmService.configuration

        var wrapUpMessages = [LLMMessage(role: "system", content: PromptTemplates.wrapUpInstruction)]
        let conversationSummary = messages.map { "\($0.role): \($0.content)" }.joined(separator: "\n")
        wrapUpMessages.append(LLMMessage(role: "user", content: "Here is the conversation:\n\n\(conversationSummary)"))

        isStreaming = true

        activeURLTask = provider.send(messages: wrapUpMessages, config: config) { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                switch result {
                case .success(let response):
                    self.parseWrapUp(response)
                    self.session?.takeaway = self.sessionTakeaway
                    self.session?.nextStep = self.sessionNextStep
                case .failure(let error):
                    print("🔴 [Chat] wrap-up generation failed: \(error)")
                    self.sessionTakeaway = "We couldn't generate a summary for this session."
                    self.sessionNextStep = "Reflect on what stood out to you from this conversation."
                    self.session?.takeaway = self.sessionTakeaway
                    self.session?.nextStep = self.sessionNextStep
                }
                self.isStreaming = false
                self.showWrapUp = true
                CoachingTipService.refreshTip(modelContext: modelContext)
            }
        }
    }

    // MARK: - LLM Response

    private func fetchResponse(
        llmMessages: [LLMMessage],
        llmService: LLMService,
        modelContext: ModelContext,
        riskAssessment: RiskAssessment?,
        userMessage: ChatMessage?
    ) {
        // Cancel any in-flight network request immediately
        activeURLTask?.cancel()
        streamingTask?.cancel()

        isStreaming = true
        errorMessage = nil

        // Generation counter: stale callbacks check this and bail out
        requestGeneration += 1
        let myGeneration = requestGeneration

        // Capture @Observable properties synchronously on MainActor
        let provider = Self.makeProvider(for: llmService.configuration)
        let config = llmService.configuration
        let currentSession = session

        print("🟡 [Chat] fetchResponse gen=\(myGeneration) with \(llmMessages.count) messages")

        // Pure URLSession callback — NO Swift Tasks for the network call.
        // The callback runs on URLSession's background queue, then we dispatch to MainActor.
        activeURLTask = provider.send(messages: llmMessages, config: config) { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                guard let self, self.requestGeneration == myGeneration else { return }

                switch result {
                case .success(let response):
                    print("🟢 [Chat] gen=\(myGeneration) got response: \(response.prefix(80))...")
                    let assistantMessage = ChatMessage(role: "assistant", content: response)
                    assistantMessage.session = currentSession
                    modelContext.insert(assistantMessage)
                    self.messages.append(assistantMessage)

                    if let assessment = riskAssessment, assessment.isFlagged {
                        self.logGuardrailEvent(
                            assessment: assessment,
                            userMessage: userMessage,
                            assistantResponse: response,
                            modelContext: modelContext
                        )
                    }

                case .failure(let error):
                    print("🔴 [Chat] gen=\(myGeneration) error: \(error)")
                    self.errorMessage = String(error.localizedDescription.prefix(150))
                }

                self.isStreaming = false
            }
        }
    }

    private static func makeProvider(for config: LLMConfiguration) -> any LLMProvider {
        switch config.provider {
        case .openai: OpenAIProvider()
        case .claude: ClaudeProvider()
        case .gemini: GeminiProvider()
        }
    }

    // MARK: - Guardrail Logging

    private func logGuardrailEvent(
        assessment: RiskAssessment,
        userMessage: ChatMessage?,
        assistantResponse: String,
        modelContext: ModelContext
    ) {
        guard let sessionId = session?.id else { return }

        let log = GuardrailLog(
            sessionId: sessionId,
            topicSlug: topic.slug,
            triggerType: assessment.triggerType ?? "unknown",
            ruleTitle: assessment.matchedRule?.title,
            userMessageExcerpt: (userMessage?.content ?? "").truncated(to: 200),
            assistantResponse: assistantResponse.truncated(to: 500)
        )
        modelContext.insert(log)
    }

    // MARK: - Helpers

    private func makePromptBuilder(
        modelContext: ModelContext,
        isFirstMessage: Bool,
        riskAssessment: RiskAssessment? = nil
    ) -> PromptBuilder {
        let personaDescriptor = FetchDescriptor<PersonaIdentity>()
        let persona = (try? modelContext.fetch(personaDescriptor))?.first ?? PersonaIdentity(
            name: "Simon", voice: "", tone: "", coachingStyle: "",
            coreBeliefs: [], riskStance: "", boundaries: []
        )

        let rules = fetchRules(modelContext: modelContext)

        let knowledgeDescriptor = FetchDescriptor<KnowledgeObject>()
        let allKnowledge = (try? modelContext.fetch(knowledgeDescriptor)) ?? []
        let topicKnowledge = Array(allKnowledge.filter { $0.topic?.slug == topic.slug }.prefix(3))

        let profileDescriptor = FetchDescriptor<FollowerProfile>()
        let profile = (try? modelContext.fetch(profileDescriptor))?.first

        let history: [ChatMessage]
        if isFirstMessage {
            history = []
        } else {
            history = Array(messages.dropLast())
        }

        return PromptBuilder(
            persona: persona,
            rules: rules,
            topic: topic,
            intent: intent?.id ?? "general",
            followerProfile: profile,
            knowledgeObjects: topicKnowledge,
            conversationHistory: history,
            isFirstMessage: isFirstMessage,
            riskAssessment: riskAssessment
        )
    }

    private func fetchRules(modelContext: ModelContext) -> [Rule] {
        let descriptor = FetchDescriptor<Rule>(sortBy: [SortDescriptor(\.priority)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func appendAssistantMessage(_ content: String, modelContext: ModelContext) {
        let message = ChatMessage(role: "assistant", content: content)
        message.session = session
        modelContext.insert(message)
        messages.append(message)
    }

    private func parseWrapUp(_ response: String) {
        let lines = response.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("TAKEAWAY:") {
                sessionTakeaway = String(trimmed.dropFirst("TAKEAWAY:".count)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("NEXT_STEP:") {
                sessionNextStep = String(trimmed.dropFirst("NEXT_STEP:".count)).trimmingCharacters(in: .whitespaces)
            }
        }

        if sessionTakeaway == nil || sessionTakeaway?.isEmpty == true {
            sessionTakeaway = response.truncated(to: 200)
        }
        if sessionNextStep == nil || sessionNextStep?.isEmpty == true {
            sessionNextStep = "Reflect on what stood out to you from this conversation."
        }
    }
}
