import Foundation
import SwiftData

@Model
final class Rule {
    var id: UUID
    var title: String
    var content: String
    var category: String
    var priority: Int
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    init(title: String, content: String, category: String, priority: Int) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.category = category
        self.priority = priority
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
