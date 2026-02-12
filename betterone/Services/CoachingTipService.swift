import Foundation
import SwiftData
import WidgetKit

@MainActor
final class CoachingTipService {

    static func refreshTip(modelContext: ModelContext) {
        var candidates: [CoachingTip] = []

        // Gather tips from KnowledgeObject heuristics and coreIdeas
        let koDescriptor = FetchDescriptor<KnowledgeObject>()
        let knowledgeObjects = (try? modelContext.fetch(koDescriptor)) ?? []

        for ko in knowledgeObjects {
            guard let topic = ko.topic else { continue }

            for heuristic in ko.heuristics {
                candidates.append(CoachingTip(
                    id: UUID().uuidString,
                    tipText: heuristic,
                    context: ko.whenToUse,
                    topicTitle: topic.title,
                    topicSlug: topic.slug,
                    topicIconName: topic.iconName,
                    source: .heuristic,
                    generatedAt: .now
                ))
            }

            candidates.append(CoachingTip(
                id: UUID().uuidString,
                tipText: ko.coreIdea,
                context: ko.whenToUse,
                topicTitle: topic.title,
                topicSlug: topic.slug,
                topicIconName: topic.iconName,
                source: .coreIdea,
                generatedAt: .now
            ))
        }

        // Gather tips from recent session takeaways
        var sessionDescriptor = FetchDescriptor<ChatSession>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        sessionDescriptor.fetchLimit = 10
        let sessions = (try? modelContext.fetch(sessionDescriptor)) ?? []

        for session in sessions {
            guard let takeaway = session.takeaway, !takeaway.isEmpty,
                  let topic = session.topic else { continue }

            candidates.append(CoachingTip(
                id: UUID().uuidString,
                tipText: takeaway,
                context: session.nextStep ?? "",
                topicTitle: topic.title,
                topicSlug: topic.slug,
                topicIconName: topic.iconName,
                source: .sessionTakeaway,
                generatedAt: .now
            ))
        }

        guard let selectedTip = selectTip(from: candidates) else { return }

        SharedStorage.saveCoachingTip(selectedTip)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func selectTip(from candidates: [CoachingTip]) -> CoachingTip? {
        guard !candidates.isEmpty else { return nil }

        // Day-seeded random: same tip all day, new tip each day
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: .now) ?? 1
        let year = calendar.component(.year, from: .now)
        let seed = year * 1000 + dayOfYear

        // Prefer session takeaways ~30% of the time
        let takeaways = candidates.filter { $0.source == .sessionTakeaway }
        let useTakeaway = !takeaways.isEmpty && (seed % 10 < 3)

        let pool = useTakeaway ? takeaways : candidates
        let index = seed % pool.count
        return pool[index]
    }
}
