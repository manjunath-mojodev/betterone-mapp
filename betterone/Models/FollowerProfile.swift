import Foundation
import SwiftData

@Model
final class FollowerProfile {
    var id: UUID
    var helpAreas: [String]
    var feedbackStyle: String
    var optionalNote: String?
    var createdAt: Date
    var updatedAt: Date

    init(helpAreas: [String], feedbackStyle: String, optionalNote: String? = nil) {
        self.id = UUID()
        self.helpAreas = helpAreas
        self.feedbackStyle = feedbackStyle
        self.optionalNote = optionalNote
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
