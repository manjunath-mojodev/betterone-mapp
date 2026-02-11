import Foundation
import SwiftData

@Model
final class KnowledgeObject {
    var id: UUID
    var topic: Topic?
    var coreIdea: String
    var whenToUse: String
    var heuristics: [String]
    var whatToAvoid: [String]
    var sourceReference: String
    var role: String
    var createdAt: Date

    init(coreIdea: String, whenToUse: String, heuristics: [String],
         whatToAvoid: [String], sourceReference: String, role: String) {
        self.id = UUID()
        self.coreIdea = coreIdea
        self.whenToUse = whenToUse
        self.heuristics = heuristics
        self.whatToAvoid = whatToAvoid
        self.sourceReference = sourceReference
        self.role = role
        self.createdAt = Date()
    }
}
