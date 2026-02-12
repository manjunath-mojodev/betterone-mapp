import WidgetKit

struct CoachingTipProvider: TimelineProvider {
    typealias Entry = CoachingTipEntry

    func placeholder(in context: Context) -> CoachingTipEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (CoachingTipEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        let tip = SharedStorage.loadCoachingTip()
        completion(CoachingTipEntry(date: .now, tip: tip))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CoachingTipEntry>) -> Void) {
        let tip = SharedStorage.loadCoachingTip()
        let entry = CoachingTipEntry(date: .now, tip: tip)

        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: .now)!)
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))

        completion(timeline)
    }
}
