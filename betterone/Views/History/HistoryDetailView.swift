import SwiftUI

struct HistoryDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let session: ChatSession

    private var topicColor: Color {
        guard let slug = session.topic?.slug else { return Theme.accent }
        return TopicCardView.colorForSlug(slug)
    }

    private var sortedMessages: [ChatMessage] {
        (session.messages ?? []).sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: Theme.spacingSM) {
                    Circle()
                        .fill(.white.opacity(0.6))
                        .frame(width: Theme.iconSizeSM, height: Theme.iconSizeSM)

                    Text(session.topic?.title ?? "Conversation")
                        .font(Theme.captionFont)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 28, height: 28)
                        .background(.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, Theme.spacingMD)
            .padding(.vertical, Theme.spacingSM)
            .background(topicColor)

            // Messages
            ScrollView {
                LazyVStack(spacing: Theme.spacingSM) {
                    ForEach(sortedMessages) { message in
                        MessageBubbleView(message: message, userBubbleColor: topicColor)
                    }

                    // Takeaway / Next Step
                    if let takeaway = session.takeaway, !takeaway.isEmpty {
                        wrapUpCard(title: "Takeaway", content: takeaway)
                    }
                    if let nextStep = session.nextStep, !nextStep.isEmpty {
                        wrapUpCard(title: "Next Step", content: nextStep)
                    }
                }
                .padding(.vertical, Theme.spacingMD)
            }
            .background(topicColor.opacity(Theme.opacitySubtle))
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(appState.showTabBar ? .visible : .hidden, for: .navigationBar)
        .onAppear { appState.showTabBar = false }
        .onDisappear { appState.showTabBar = true }
    }

    private func wrapUpCard(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingXS) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(topicColor)
            Text(content)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(Theme.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
        .padding(.horizontal, Theme.spacingMD)
        .padding(.top, Theme.spacingSM)
    }
}
