import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \ChatSession.startedAt, order: .reverse) private var sessions: [ChatSession]

    private var sessionsWithMessages: [ChatSession] {
        sessions.filter { ($0.messages?.isEmpty == false) }
    }

    var body: some View {
        Group {
            if sessionsWithMessages.isEmpty {
                ContentUnavailableView(
                    "No Conversations Yet",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Your past conversations will appear here.")
                )
            } else {
                List(sessionsWithMessages) { session in
                    NavigationLink(value: session) {
                        HistoryRow(session: session)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Row

private struct HistoryRow: View {
    let session: ChatSession

    private var topicColor: Color {
        guard let slug = session.topic?.slug else { return Theme.accent }
        return TopicCardView.colorForSlug(slug)
    }

    private var firstUserMessage: String? {
        session.messages?
            .sorted { $0.createdAt < $1.createdAt }
            .first { $0.role == "user" }?
            .content
    }

    private var intentLabel: String {
        AppConstants.sessionIntents.first { $0.id == session.intent }?.title ?? session.intent
    }

    var body: some View {
        HStack(spacing: Theme.spacingMD) {
            RoundedRectangle(cornerRadius: 3)
                .fill(topicColor)
                .frame(width: 6)

            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                HStack {
                    Text(session.topic?.title ?? "Unknown Topic")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)

                    Spacer()

                    Text(session.startedAt, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }

                Text(intentLabel)
                    .font(.caption)
                    .foregroundStyle(topicColor)

                if let preview = firstUserMessage {
                    Text(preview)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, Theme.spacingXS)
    }
}
