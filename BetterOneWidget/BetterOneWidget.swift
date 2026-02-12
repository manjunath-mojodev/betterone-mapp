import WidgetKit
import SwiftUI

struct BetterOneCoachingWidget: Widget {
    let kind: String = "BetterOneCoachingTip"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CoachingTipProvider()) { entry in
            CoachingTipEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Daily Coaching Tip")
        .description("Get a daily insight from your BetterOne coaching topics.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct CoachingTipEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: CoachingTipEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallCoachingTipView(entry: entry)
        case .systemMedium:
            MediumCoachingTipView(entry: entry)
        default:
            SmallCoachingTipView(entry: entry)
        }
    }
}

@main
struct BetterOneWidgetBundle: WidgetBundle {
    var body: some Widget {
        BetterOneCoachingWidget()
    }
}
