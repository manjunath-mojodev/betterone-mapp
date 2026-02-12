import SwiftUI

struct WidgetSetupGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingLG) {
                // Header
                VStack(spacing: Theme.spacingSM) {
                    Image(systemName: "rectangle.on.rectangle")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.accent)

                    Text("Daily Coaching Tip")
                        .font(Theme.titleFont)

                    Text("Get a fresh coaching insight on your Home Screen every day.")
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, Theme.spacingSM)

                // Steps
                VStack(alignment: .leading, spacing: Theme.spacingMD) {
                    StepRow(number: 1, title: "Long-press your Home Screen", detail: "Touch and hold any empty area until the apps start to jiggle.")

                    StepRow(number: 2, title: "Tap the + button", detail: "It appears in the top-left corner of the screen.")

                    StepRow(number: 3, title: "Search for BetterOne", detail: "Type \"BetterOne\" in the widget search bar.")

                    StepRow(number: 4, title: "Choose a size", detail: "Select Small for a glanceable tip, or Medium for more detail.")

                    StepRow(number: 5, title: "Tap Add Widget", detail: "Place it wherever you like, then tap Done.")
                }

                // Tip
                HStack(alignment: .top, spacing: Theme.spacingSM) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(Theme.warning)
                        .font(.system(size: 16))
                        .padding(.top, 2)

                    Text("The widget updates with a new tip each day. Tap it to jump straight into that topic.")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(Theme.spacingMD)
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            }
            .padding(Theme.spacingMD)
        }
        .navigationTitle("Widget Setup")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct StepRow: View {
    let number: Int
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.spacingMD) {
            Text("\(number)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Theme.accent)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.headlineFont)

                Text(detail)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}
