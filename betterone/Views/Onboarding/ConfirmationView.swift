import SwiftUI

struct ConfirmationView: View {
    let viewModel: OnboardingViewModel
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: Theme.spacingXL) {
            Spacer()

            Image(systemName: "checkmark.circle")
                .font(.system(size: Theme.iconSizeXL))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)

            VStack(spacing: Theme.spacingMD) {
                Text("You're all set")
                    .font(Theme.titleFont)

                VStack(alignment: .leading, spacing: Theme.spacingSM) {
                    Label {
                        Text(viewModel.selectedHelpAreas.joined(separator: ", "))
                    } icon: {
                        Image(systemName: "target")
                    }

                    Label {
                        Text(viewModel.feedbackStyle == "gentle" ? "Gentle & reflective" : "Direct & practical")
                    } icon: {
                        Image(systemName: "bubble.left")
                    }
                }
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Button(action: onComplete) {
                Text("Let's go")
                    .font(Theme.headlineFont)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.spacingMD)
                    .background(Theme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            }
            .accessibilityHint("Start using \(AppConstants.appName)")
        }
        .padding(Theme.spacingLG)
    }
}
