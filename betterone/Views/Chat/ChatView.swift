import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(LLMService.self) private var llmService
    @Environment(AppState.self) private var appState
    @State var viewModel: ChatViewModel

    private var topicColor: Color {
        TopicCardView.colorForSlug(viewModel.topic.slug)
    }

    init(topic: Topic, intent: SessionIntent? = nil) {
        _viewModel = State(initialValue: ChatViewModel(topic: topic, intent: intent))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with topic color + close button
            HStack {
                HStack(spacing: Theme.spacingSM) {
                    Circle()
                        .fill(.white.opacity(0.6))
                        .frame(width: Theme.iconSizeSM, height: Theme.iconSizeSM)

                    Text("Talking with \(AppConstants.creatorName) about \(viewModel.topic.title)")
                        .font(Theme.captionFont)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                if viewModel.hasSelectedIntent {
                    Button {
                        viewModel.endSession(modelContext: modelContext, llmService: llmService)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(width: 28, height: 28)
                            .background(.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("End session")
                    .accessibilityHint("End this coaching session")
                }
            }
            .padding(.horizontal, Theme.spacingMD)
            .padding(.vertical, Theme.spacingSM)
            .background(topicColor)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: Theme.spacingSM) {
                        if !viewModel.hasSelectedIntent {
                            intentPicker
                        } else if viewModel.messages.isEmpty && !viewModel.isStreaming {
                            emptyState
                        }

                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(message: message, userBubbleColor: topicColor)
                                .id(message.id)
                        }

                        if viewModel.isStreaming {
                            HStack {
                                LoadingIndicator()
                                    .padding(.leading, Theme.spacingMD)
                                Spacer()
                            }
                            .id("streaming-indicator")
                            .accessibilityLabel("\(AppConstants.creatorName) is thinking")
                        }
                    }
                    .padding(.vertical, Theme.spacingSM)
                }
                .scrollDismissesKeyboard(.interactively)
                .background(topicColor.opacity(Theme.opacitySubtle))
                .onChange(of: viewModel.messages.last?.content) {
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.messages.count) {
                    scrollToBottom(proxy: proxy)
                }
            }

            if let error = viewModel.errorMessage {
                HStack(spacing: Theme.spacingSM) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.warning)
                    Text(error)
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Button {
                        viewModel.errorMessage = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .accessibilityLabel("Dismiss error")
                }
                .padding(.horizontal, Theme.spacingMD)
                .padding(.vertical, Theme.spacingSM)
                .background(Theme.warning.opacity(Theme.opacitySubtle))
            }

            if viewModel.hasSelectedIntent {
                ChatInputView(
                    text: $viewModel.inputText,
                    isDisabled: false
                ) {
                    viewModel.sendMessage(modelContext: modelContext, llmService: llmService)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.hasSelectedIntent)
        .toolbar(viewModel.hasSelectedIntent ? .hidden : .visible, for: .navigationBar)
        .sheet(isPresented: $viewModel.showWrapUp) {
            SessionWrapUpView(
                topicTitle: viewModel.topic.title,
                takeaway: viewModel.sessionTakeaway,
                nextStep: viewModel.sessionNextStep
            ) {
                viewModel.showWrapUp = false
                appState.selectedTab = 0
                dismiss()
            }
            .presentationDetents([.medium])
        }
        .onAppear {
            appState.showTabBar = false
            if viewModel.hasSelectedIntent {
                viewModel.startSession(modelContext: modelContext, llmService: llmService)
            }
        }
        .onDisappear {
            appState.showTabBar = true
        }
    }

    // MARK: - Intent Picker (Conversational)

    private var intentPicker: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            // Greeting bubble
            HStack {
                Text(viewModel.greeting)
                    .font(Theme.bodyFont)
                    .padding(Theme.spacingMD)
                    .background(Color(.systemBackground))
                    .foregroundStyle(Theme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)

                Spacer(minLength: Theme.spacingXL)
            }
            .padding(.horizontal, Theme.spacingMD)

            // Intent question + radio options as a single bubble
            VStack(alignment: .leading, spacing: Theme.spacingSM) {
                Text("What would make this useful?")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, Theme.spacingMD)
                    .padding(.top, Theme.spacingMD)

                ForEach(AppConstants.sessionIntents) { intent in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(Theme.animationDefault) {
                            viewModel.selectIntent(intent, modelContext: modelContext, llmService: llmService)
                        }
                    } label: {
                        HStack(spacing: Theme.spacingSM) {
                            Circle()
                                .strokeBorder(Theme.textSecondary.opacity(0.4), lineWidth: 1.5)
                                .frame(width: 20, height: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(intent.title)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(intent.description)
                                    .font(Theme.captionFont)
                                    .foregroundStyle(Theme.textSecondary)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, Theme.spacingMD)
                        .padding(.vertical, Theme.spacingSM + 2)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(intent.title): \(intent.description)")
                    .accessibilityHint("Start session with this intent")
                }

                Spacer().frame(height: Theme.spacingSM)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
            .padding(.horizontal, Theme.spacingMD)
            .padding(.trailing, Theme.spacingXL)
        }
    }

    // MARK: - Empty & Scroll

    private var emptyState: some View {
        VStack(spacing: Theme.spacingSM) {
            ProgressView()
            Text("Starting your session...")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.spacingXL)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading session")
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if viewModel.isStreaming {
            withAnimation { proxy.scrollTo("streaming-indicator", anchor: .bottom) }
        } else if let lastId = viewModel.messages.last?.id {
            withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
        }
    }
}

