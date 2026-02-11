import Foundation
import SwiftData

@Model
final class Topic {
    var id: UUID
    var slug: String
    var title: String
    var subtitle: String
    var iconName: String
    var sortOrder: Int
    var isActive: Bool

    @Relationship(deleteRule: .cascade, inverse: \KnowledgeObject.topic)
    var knowledgeObjects: [KnowledgeObject]?

    @Relationship(deleteRule: .cascade, inverse: \ChatSession.topic)
    var sessions: [ChatSession]?

    init(slug: String, title: String, subtitle: String, iconName: String, sortOrder: Int) {
        self.id = UUID()
        self.slug = slug
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.isActive = true
    }
}
