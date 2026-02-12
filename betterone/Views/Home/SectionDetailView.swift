import SwiftUI
import SwiftData

struct SectionDetailView: View {
    let selection: SectionSelection
    @Environment(SubscriptionService.self) private var subscriptionService
    @Query(sort: \Topic.sortOrder) private var allTopics: [Topic]
    @State private var showPaywall = false

    private var topics: [Topic] {
        allTopics.filter { selection.topicIDs.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingMD) {
                ForEach(topics) { topic in
                    if topic.isPremium && !subscriptionService.isSubscribed {
                        Button {
                            showPaywall = true
                        } label: {
                            SectionDetailCard(topic: topic, showPremiumLock: true)
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink(value: topic) {
                            SectionDetailCard(topic: topic, showPremiumBadge: topic.isPremium)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, Theme.spacingLG)
            .padding(.top, Theme.spacingSM)
        }
        .navigationTitle(selection.title)
        .background(Color(uiColor: .systemGroupedBackground))
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

private struct SectionDetailCard: View {
    let topic: Topic
    var showPremiumLock: Bool = false
    var showPremiumBadge: Bool = false

    var body: some View {
        HStack(spacing: Theme.spacingMD) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: topic.iconName)
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 56, height: 56)
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

            if showPremiumLock || showPremiumBadge {
                PremiumBadge()
            }

            if !showPremiumLock {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(Theme.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
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
}
