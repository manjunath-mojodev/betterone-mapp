import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Theme.spacingXL) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: Theme.iconSizeXL))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)

            VStack(spacing: Theme.spacingMD) {
                Text("Welcome to \(AppConstants.appName)")
                    .font(Theme.titleFont)

                Text("Your AI coach, guided by \(AppConstants.creatorName)'s thinking.\nThoughtful. Grounded. No fluff.")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(action: onContinue) {
                Text("Get Started")
                    .font(Theme.headlineFont)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.spacingMD)
                    .background(Theme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            }
            .accessibilityHint("Begin setting up your coaching profile")
        }
        .padding(Theme.spacingLG)
    }
}
