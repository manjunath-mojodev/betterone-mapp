import Foundation

struct CoachingTip: Codable {
    let id: String
    let tipText: String
    let context: String
    let topicTitle: String
    let topicSlug: String
    let topicIconName: String
    let source: TipSource
    let generatedAt: Date

    enum TipSource: String, Codable {
        case heuristic
        case coreIdea
        case sessionTakeaway
    }
}
