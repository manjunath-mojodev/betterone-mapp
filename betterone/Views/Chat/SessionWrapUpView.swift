import SwiftUI
import StoreKit

struct SessionWrapUpView: View {
    let topicTitle: String
    let takeaway: String?
    let nextStep: String?
    let onDismiss: () -> Void

    @State private var selectedRating: Int = 0
    @Environment(\.requestReview) private var requestReview

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, Theme.spacingLG)

            // Header — topic name gives context to the summary
            Text(topicTitle)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spacingLG)
                .padding(.bottom, Theme.spacingLG)

            // Cards
            VStack(spacing: Theme.spacingSM) {
                if let takeaway, !takeaway.isEmpty {
                    wrapUpCard(
                        label: "Takeaway",
                        icon: "lightbulb.fill",
                        iconColor: Theme.warning,
                        content: takeaway
                    )
                }

                if let nextStep, !nextStep.isEmpty {
                    wrapUpCard(
                        label: "Next Step",
                        icon: "arrow.right.circle.fill",
                        iconColor: Theme.accent,
                        content: nextStep
                    )
                }

                if (takeaway == nil || takeaway?.isEmpty == true) &&
                   (nextStep == nil || nextStep?.isEmpty == true) {
                    Text("Thanks for showing up today. Every conversation is a step forward.")
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, Theme.spacingMD)
                }
            }
            .padding(.horizontal, Theme.spacingLG)

            // Star Rating
            VStack(spacing: Theme.spacingSM) {
                Text("How was this session?")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textSecondary)

                HStack(spacing: Theme.spacingSM) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedRating = star
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if star >= 4 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    requestReview()
                                }
                            }
                        } label: {
                            Image(systemName: star <= selectedRating ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundStyle(star <= selectedRating ? .yellow : Theme.textSecondary.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
                    }
                }
            }
            .padding(.top, Theme.spacingLG)

            Spacer()

            // Done button
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onDismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            }
            .padding(.horizontal, Theme.spacingLG)
            .padding(.bottom, Theme.spacingLG)
            .accessibilityHint("Close session summary and return home")
        }
        .interactiveDismissDisabled()
    }

    private func wrapUpCard(label: String, icon: String, iconColor: Color, content: String) -> some View {
        HStack(alignment: .top, spacing: Theme.spacingSM + 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(iconColor)
                .frame(width: 24, height: 24)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                Text(content)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.spacingMD)
        .background(Theme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(content)")
    }
}
