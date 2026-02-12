import SwiftUI
import SwiftData
import WidgetKit

@main
struct betteroneApp: App {
    @State private var appState = AppState()
    @State private var llmService = LLMService()
    @State private var subscriptionService = SubscriptionService()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FollowerProfile.self,
            PersonaIdentity.self,
            Rule.self,
            Topic.self,
            KnowledgeObject.self,
            ChatSession.self,
            ChatMessage.self,
            GuardrailLog.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(llmService)
                .environment(subscriptionService)
                .onAppear {
                    seedDataIfNeeded()
                    subscriptionService.configure()
                    CoachingTipService.refreshTip(modelContext: sharedModelContainer.mainContext)
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == SharedConstants.deepLinkScheme,
              url.host == "topic",
              let slug = url.pathComponents.dropFirst().first else { return }
        appState.pendingTopicSlug = slug
        appState.selectedTab = 0
    }

    private func seedDataIfNeeded() {
        let context = sharedModelContainer.mainContext

        // Seed topics
        let topicDescriptor = FetchDescriptor<Topic>()
        let existingTopics = (try? context.fetch(topicDescriptor)) ?? []
        if existingTopics.isEmpty {
            if let url = Bundle.main.url(forResource: "DefaultTopics", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let topics = try? JSONDecoder().decode([SeedTopic].self, from: data) {
                for seed in topics {
                    let topic = Topic(slug: seed.slug, title: seed.title, subtitle: seed.subtitle,
                                      iconName: seed.iconName, sortOrder: seed.sortOrder, isPremium: seed.isPremium)
                    context.insert(topic)
                }
            }
        }

        // Seed persona
        let personaDescriptor = FetchDescriptor<PersonaIdentity>()
        let existingPersonas = (try? context.fetch(personaDescriptor)) ?? []
        if existingPersonas.isEmpty {
            if let url = Bundle.main.url(forResource: "DefaultPersona", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let seed = try? JSONDecoder().decode(SeedPersona.self, from: data) {
                let persona = PersonaIdentity(name: seed.name, voice: seed.voice, tone: seed.tone,
                                              coachingStyle: seed.coachingStyle, coreBeliefs: seed.coreBeliefs,
                                              riskStance: seed.riskStance, boundaries: seed.boundaries)
                context.insert(persona)
            }
        }

        // Seed rules
        let ruleDescriptor = FetchDescriptor<Rule>()
        let existingRules = (try? context.fetch(ruleDescriptor)) ?? []
        if existingRules.isEmpty {
            if let url = Bundle.main.url(forResource: "DefaultRules", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let seeds = try? JSONDecoder().decode([SeedRule].self, from: data) {
                for seed in seeds {
                    let rule = Rule(title: seed.title, content: seed.content,
                                    category: seed.category, priority: seed.priority)
                    context.insert(rule)
                }
            }
        }

        // Seed knowledge objects
        let koDescriptor = FetchDescriptor<KnowledgeObject>()
        let existingKO = (try? context.fetch(koDescriptor)) ?? []
        if existingKO.isEmpty {
            let allTopics = (try? context.fetch(FetchDescriptor<Topic>())) ?? []
            if let url = Bundle.main.url(forResource: "DefaultKnowledge", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let seeds = try? JSONDecoder().decode([SeedKnowledgeObject].self, from: data) {
                for seed in seeds {
                    let ko = KnowledgeObject(
                        coreIdea: seed.coreIdea,
                        whenToUse: seed.whenToUse,
                        heuristics: seed.heuristics,
                        whatToAvoid: seed.whatToAvoid,
                        sourceReference: seed.sourceReference,
                        role: seed.role
                    )
                    if let matchingTopic = allTopics.first(where: { $0.slug == seed.topicSlug }) {
                        ko.topic = matchingTopic
                    }
                    context.insert(ko)
                }
            }
        }
    }
}

// MARK: - Seed Data Codable Types

private struct SeedTopic: Codable {
    let slug: String
    let title: String
    let subtitle: String
    let iconName: String
    let sortOrder: Int
    let isPremium: Bool
}

private struct SeedPersona: Codable {
    let name: String
    let voice: String
    let tone: String
    let coachingStyle: String
    let coreBeliefs: [String]
    let riskStance: String
    let boundaries: [String]
}

private struct SeedRule: Codable {
    let title: String
    let content: String
    let category: String
    let priority: Int
}

private struct SeedKnowledgeObject: Codable {
    let topicSlug: String
    let coreIdea: String
    let whenToUse: String
    let heuristics: [String]
    let whatToAvoid: [String]
    let sourceReference: String
    let role: String
}
