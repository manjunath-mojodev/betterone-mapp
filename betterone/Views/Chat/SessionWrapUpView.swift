import SwiftUI

struct SessionWrapUpView: View {
    let takeaway: String?
    let nextStep: String?
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: Theme.spacingLG) {
            Image(systemName: "sparkles")
                .font(.system(size: Theme.spacingLG))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)

            Text("Session Wrap-Up")
                .font(Theme.titleFont)

            if let takeaway, !takeaway.isEmpty {
                wrapUpCard(label: "Takeaway", icon: "lightbulb", content: takeaway)
            }

            if let nextStep, !nextStep.isEmpty {
                wrapUpCard(label: "Next Step", icon: "arrow.right.circle", content: nextStep)
            }

            if (takeaway == nil || takeaway?.isEmpty == true) &&
               (nextStep == nil || nextStep?.isEmpty == true) {
                Text("Thanks for showing up today. Every conversation is a step forward.")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onDismiss) {
                Text("Done")
                    .font(Theme.headlineFont)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.spacingMD)
                    .background(Theme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            }
            .accessibilityHint("Close session summary and return home")
        }
        .padding(Theme.spacingLG)
    }

    private func wrapUpCard(label: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            Label(label, systemImage: icon)
                .font(Theme.headlineFont)
            Text(content)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.spacingMD)
        .background(Theme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(content)")
    }
}
