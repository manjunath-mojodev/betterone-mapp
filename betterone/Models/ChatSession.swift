import Foundation
import SwiftData

@Model
final class ChatSession {
    var id: UUID
    var topic: Topic?
    var intent: String
    var startedAt: Date
    var endedAt: Date?
    var takeaway: String?
    var nextStep: String?

    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.session)
    var messages: [ChatMessage]?

    init(intent: String) {
        self.id = UUID()
        self.intent = intent
        self.startedAt = Date()
    }
}
