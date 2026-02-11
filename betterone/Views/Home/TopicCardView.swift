import SwiftUI

struct TopicCardView: View {
    let topic: Topic

    private var cardColor: Color {
        TopicCardView.colorForSlug(topic.slug)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            Image(systemName: topic.iconName)
                .font(.title2)
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 50, height: 50)
                .background(.white.opacity(0.2))
                .clipShape(Circle())

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
        .background(cardColor.gradient)
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
