import Foundation

enum AppConstants {
    static let creatorName = "Simon"
    static let appName = "BetterOne"
    static let creatorModePasscode = "simon2024"

    /// True for DEBUG builds and TestFlight installs, false for App Store production.
    static var isDevelopmentBuild: Bool {
        #if DEBUG
        return true
        #else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }

    static let helpAreas = [
        "Goal Setting",
        "Career Advice",
        "Time Management",
        "Focus & Systems"
    ]

    static let sessionIntents = [
        SessionIntent(id: "clarity", title: "Clarity", description: "I want to see things more clearly"),
        SessionIntent(id: "direction", title: "Direction", description: "I need help choosing a path"),
        SessionIntent(id: "next_step", title: "A next step", description: "I want something concrete to do"),
        SessionIntent(id: "thinking_out_loud", title: "Thinking out loud", description: "I just need space to process")
    ]
}

struct SessionIntent: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
}
