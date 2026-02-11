import SwiftUI
import SwiftData

@Observable
final class OnboardingViewModel {
    var currentStep = 0
    var selectedHelpAreas: Set<String> = []
    var feedbackStyle: String = "gentle"
    var optionalNote: String = ""

    var canProceedFromContext: Bool {
        !selectedHelpAreas.isEmpty
    }

    func completeOnboarding(modelContext: ModelContext, appState: AppState) {
        let profile = FollowerProfile(
            helpAreas: Array(selectedHelpAreas),
            feedbackStyle: feedbackStyle,
            optionalNote: optionalNote.isEmpty ? nil : optionalNote
        )
        modelContext.insert(profile)
        appState.onboardingComplete = true
    }
}
