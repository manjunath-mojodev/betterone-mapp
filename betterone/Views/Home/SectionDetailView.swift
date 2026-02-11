import SwiftUI
import SwiftData

struct SectionDetailView: View {
    let selection: SectionSelection
    @Query(sort: \Topic.sortOrder) private var allTopics: [Topic]

    private var topics: [Topic] {
        allTopics.filter { selection.topicIDs.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingMD) {
                ForEach(topics) { topic in
                    NavigationLink(value: topic) {
                        SectionDetailCard(topic: topic)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.spacingLG)
            .padding(.top, Theme.spacingSM)
        }
        .navigationTitle(selection.title)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

private struct SectionDetailCard: View {
    let topic: Topic

    var body: some View {
        HStack(spacing: Theme.spacingMD) {
            Image(systemName: topic.iconName)
                .font(.title2)
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 56, height: 56)
                .background(.white.opacity(0.2))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(topic.title)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(topic.subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(Theme.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TopicCardView.colorForSlug(topic.slug).gradient)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
    }
}
