import SwiftUI

@Observable
final class AppState {
    var onboardingComplete: Bool {
        didSet { UserDefaults.standard.set(onboardingComplete, forKey: "onboardingComplete") }
    }
    var showTabBar: Bool = true

    init() {
        self.onboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")
    }
}
