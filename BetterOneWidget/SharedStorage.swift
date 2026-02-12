import Foundation

enum SharedStorage {
    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: SharedConstants.appGroupIdentifier)
    }

    static func saveCoachingTip(_ tip: CoachingTip) {
        guard let data = try? JSONEncoder().encode(tip) else { return }
        sharedDefaults?.set(data, forKey: SharedConstants.coachingTipKey)
    }

    static func loadCoachingTip() -> CoachingTip? {
        guard let data = sharedDefaults?.data(forKey: SharedConstants.coachingTipKey),
              let tip = try? JSONDecoder().decode(CoachingTip.self, from: data) else {
            return nil
        }
        return tip
    }
}
