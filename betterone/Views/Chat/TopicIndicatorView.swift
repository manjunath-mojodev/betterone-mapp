import SwiftUI

struct TopicIndicatorView: View {
    let topicTitle: String
    let topicSlug: String

    private var topicColor: Color {
        TopicCardView.colorForSlug(topicSlug)
    }

    var body: some View {
        HStack(spacing: Theme.spacingSM) {
            Circle()
                .fill(.white.opacity(0.6))
                .frame(width: Theme.iconSizeSM, height: Theme.iconSizeSM)

            Text("Talking with \(AppConstants.creatorName) about \(topicTitle)")
                .font(Theme.captionFont)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, Theme.spacingMD)
        .padding(.vertical, Theme.spacingSM)
        .frame(maxWidth: .infinity)
        .background(topicColor)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Session topic: \(topicTitle) with \(AppConstants.creatorName)")
    }
}
