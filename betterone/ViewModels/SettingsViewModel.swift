import SwiftUI
import SwiftData

@Observable
final class SettingsViewModel {
    var profile: FollowerProfile?
    var selectedHelpAreas: Set<String> = []
    var feedbackStyle: String = "gentle"
    var optionalNote: String = ""

    func loadProfile(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<FollowerProfile>()
        profile = try? modelContext.fetch(descriptor).first
        if let profile {
            selectedHelpAreas = Set(profile.helpAreas)
            feedbackStyle = profile.feedbackStyle
            optionalNote = profile.optionalNote ?? ""
        }
    }

    func saveProfile(modelContext: ModelContext) {
        guard let profile else { return }
        profile.helpAreas = Array(selectedHelpAreas)
        profile.feedbackStyle = feedbackStyle
        profile.optionalNote = optionalNote.isEmpty ? nil : optionalNote
        profile.updatedAt = Date()
    }
}
