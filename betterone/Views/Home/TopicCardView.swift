import SwiftUI

struct TopicCardView: View {
    let topic: Topic
    var showPremiumLock: Bool = false
    var showPremiumBadge: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack {
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: topic.iconName)
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: 50, height: 50)
                        .background(.white.opacity(0.2))
                        .clipShape(Circle())

                    if showPremiumLock {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(.black.opacity(0.5))
                            .clipShape(Circle())
                            .offset(x: 2, y: 2)
                    }
                }

                Spacer()

                if showPremiumLock || showPremiumBadge {
                    PremiumBadge()
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 4) {
                Text(topic.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(topic.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(width: 160, height: 180)
        .padding(Theme.spacingMD)
        .background(
            ZStack {
                Rectangle().fill(TopicCardView.colorForSlug(topic.slug).gradient)
                if showPremiumLock {
                    Rectangle().fill(.ultraThinMaterial)
                    Rectangle().fill(.black.opacity(0.15))
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
    }

    // Deterministic color palette based on slug hash
    private static let palette: [Color] = [
        Color(red: 0.95, green: 0.75, blue: 0.20),  // golden yellow
        Color(red: 0.35, green: 0.80, blue: 0.75),  // teal / mint
        Color(red: 0.90, green: 0.30, blue: 0.30),  // coral red
        Color(red: 0.55, green: 0.45, blue: 0.85),  // soft purple
        Color(red: 0.25, green: 0.60, blue: 0.90),  // sky blue
        Color(red: 0.90, green: 0.55, blue: 0.25),  // warm orange
        Color(red: 0.40, green: 0.75, blue: 0.40),  // fresh green
        Color(red: 0.85, green: 0.40, blue: 0.65),  // pink
        Color(red: 0.30, green: 0.50, blue: 0.70),  // slate blue
        Color(red: 0.70, green: 0.65, blue: 0.25),  // olive gold
    ]

    static func colorForSlug(_ slug: String) -> Color {
        let hash = abs(slug.hashValue)
        return palette[hash % palette.count]
    }
}

// MARK: - Premium Badge

struct PremiumBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "crown.fill")
                .font(.system(size: 10, weight: .bold))
            Text("PRO")
                .font(.system(size: 9, weight: .heavy))
        }
        .foregroundStyle(
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.85, blue: 0.3), Color(red: 0.9, green: 0.65, blue: 0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.black.opacity(0.55))
                .overlay(
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.9, blue: 0.5).opacity(0.6), Color(red: 0.85, green: 0.6, blue: 0.1).opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
    }
}
