import Foundation
import SwiftData

@Model
final class PersonaIdentity {
    var id: UUID
    var name: String
    var voice: String
    var tone: String
    var coachingStyle: String
    var coreBeliefs: [String]
    var riskStance: String
    var boundaries: [String]
    var updatedAt: Date

    init(name: String, voice: String, tone: String, coachingStyle: String,
         coreBeliefs: [String], riskStance: String, boundaries: [String]) {
        self.id = UUID()
        self.name = name
        self.voice = voice
        self.tone = tone
        self.coachingStyle = coachingStyle
        self.coreBeliefs = coreBeliefs
        self.riskStance = riskStance
        self.boundaries = boundaries
        self.updatedAt = Date()
    }
}
