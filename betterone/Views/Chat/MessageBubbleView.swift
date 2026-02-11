import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
    var userBubbleColor: Color = Theme.userBubble

    private var isUser: Bool { message.role == "user" }

    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: Theme.spacingXS) {
            HStack {
                if isUser { Spacer(minLength: Theme.spacingXL) }

                Text(message.content)
                    .font(Theme.bodyFont)
                    .padding(Theme.spacingMD)
                    .background(isUser ? userBubbleColor : Color(.systemBackground))
                    .foregroundStyle(isUser ? .white : Theme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
                    .textSelection(.enabled)

                if !isUser { Spacer(minLength: Theme.spacingXL) }
            }

            Text(message.createdAt, format: .dateTime.hour().minute())
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary.opacity(0.6))
                .padding(.horizontal, Theme.spacingXS)
        }
        .padding(.horizontal, Theme.spacingMD)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isUser ? "You" : AppConstants.creatorName) said: \(message.content), at \(message.createdAt.formatted(date: .omitted, time: .shortened))")
    }
}
