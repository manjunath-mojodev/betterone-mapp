import WidgetKit

struct CoachingTipEntry: TimelineEntry {
    let date: Date
    let tip: CoachingTip?

    static var placeholder: CoachingTipEntry {
        CoachingTipEntry(
            date: .now,
            tip: CoachingTip(
                id: "placeholder",
                tipText: "Identify your top 3 priorities before starting the day.",
                context: "When you feel busy but not productive.",
                topicTitle: "Productivity Principles",
                topicSlug: "productivity-principles",
                topicIconName: "bolt",
                source: .heuristic,
                generatedAt: .now
            )
        )
    }
}
