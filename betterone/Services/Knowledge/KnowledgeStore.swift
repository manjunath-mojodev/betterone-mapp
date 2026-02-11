import Foundation
import SwiftData

final class KnowledgeStore {
    func fetchForTopic(topicSlug: String, modelContext: ModelContext, limit: Int = 3) -> [KnowledgeObject] {
        let descriptor = FetchDescriptor<KnowledgeObject>()
        let all = (try? modelContext.fetch(descriptor)) ?? []
        return Array(all.filter { $0.topic?.slug == topicSlug }.prefix(limit))
    }
}
