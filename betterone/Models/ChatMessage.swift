import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id: UUID
    var session: ChatSession?
    var role: String
    var content: String
    var createdAt: Date
    var riskFlagged: Bool

    init(role: String, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.createdAt = Date()
        self.riskFlagged = false
    }
}
