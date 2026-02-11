import Foundation
import SwiftData

@Model
final class GuardrailLog {
    var id: UUID
    var sessionId: UUID
    var topicSlug: String
    var triggerType: String
    var ruleTitle: String?
    var userMessageExcerpt: String
    var assistantResponse: String
    var timestamp: Date

    init(sessionId: UUID, topicSlug: String, triggerType: String,
         ruleTitle: String?, userMessageExcerpt: String, assistantResponse: String) {
        self.id = UUID()
        self.sessionId = sessionId
        self.topicSlug = topicSlug
        self.triggerType = triggerType
        self.ruleTitle = ruleTitle
        self.userMessageExcerpt = userMessageExcerpt
        self.assistantResponse = assistantResponse
        self.timestamp = Date()
    }
}
