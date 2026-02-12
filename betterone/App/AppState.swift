import SwiftUI

@Observable
final class AppState {
    var onboardingComplete: Bool {
        didSet { UserDefaults.standard.set(onboardingComplete, forKey: "onboardingComplete") }
    }
    var showTabBar: Bool = true
    var selectedTab: Int = 0
    var pendingTopicSlug: String?

    init() {
        self.onboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")
    }
}
