import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionService.self) private var subscriptionService
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \Topic.sortOrder) private var topics: [Topic]
    @Query private var sessions: [ChatSession]
    
    private var notionSystems: [Topic] {
        topics.filter { topic in
            ["notion-life-os", "simplified-life-os", "client-content-os", "design-workspace"].contains(topic.slug)
        }
    }

    private var productivityCoaching: [Topic] {
        topics.filter { topic in
            ["goal-setting", "habit-tracking", "task-project-management", "productivity-principles"].contains(topic.slug)
        }
    }

    private var aiNotionMastery: [Topic] {
        topics.filter { topic in
            ["ai-agent-os", "notion-foundations", "second-brain", "info-org-capture"].contains(topic.slug)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingLG) {
                // Custom Header
                HStack {
                    Text("BetterMe")
                        .font(.largeTitle.bold())
                    
                    Spacer()
                    
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.accent)
                    }
                }
                .padding(.horizontal, Theme.spacingLG)
                .padding(.top, Theme.spacingSM)
                
                // Notion Systems Section
                if !notionSystems.isEmpty {
                    TopicSection(title: "Notion Systems", topics: notionSystems)
                }
                
                // Productivity & Coaching Section
                if !productivityCoaching.isEmpty {
                    TopicSection(title: "Productivity & Coaching", topics: productivityCoaching)
                }

                // AI & Notion Mastery Section
                if !aiNotionMastery.isEmpty {
                    TopicSection(title: "AI & Notion Mastery", topics: aiNotionMastery)
                }
            }
            .padding(.bottom, 100)
        }
        .navigationBarHidden(true)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

struct TopicSection: View {
    let title: String
    let topics: [Topic]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            NavigationLink(value: SectionSelection(title: title, topicIDs: topics.map(\.id))) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundStyle(Theme.textPrimary)

                    Image(systemName: "chevron.right")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)

                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Theme.spacingLG)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.spacingMD) {
                    ForEach(topics) { topic in
                        NavigationLink(value: topic) {
                            TopicCardView(topic: topic)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.spacingLG)
            }
        }
    }
}

// MARK: - Section Navigation

struct SectionSelection: Hashable {
    let title: String
    let topicIDs: [UUID]
}
