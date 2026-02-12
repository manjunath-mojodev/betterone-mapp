import SwiftUI
import WidgetKit

// MARK: - Small Widget View

struct SmallCoachingTipView: View {
    let entry: CoachingTipEntry

    var body: some View {
        if let tip = entry.tip {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: tip.topicIconName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))

                    Text(tip.topicTitle)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Text(tip.tipText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(14)
            .background(Color(.systemIndigo).gradient)
            .widgetURL(URL(string: "\(SharedConstants.deepLinkScheme)://topic/\(tip.topicSlug)"))
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.7))
            Text("Open BetterOne for your daily tip")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(14)
        .background(Color(.systemIndigo).gradient)
    }
}

// MARK: - Medium Widget View

struct MediumCoachingTipView: View {
    let entry: CoachingTipEntry

    var body: some View {
        if let tip = entry.tip {
            HStack(spacing: 12) {
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: tip.topicIconName)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: 48, height: 48)
                        .background(.white.opacity(0.2))
                        .clipShape(Circle())

                    Text(tip.topicTitle)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(width: 70)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(tip.source.displayLabel)
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.6))
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Text(tip.tipText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    if !tip.context.isEmpty {
                        Text(tip.context)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(14)
            .background(Color(.systemIndigo).gradient)
            .widgetURL(URL(string: "\(SharedConstants.deepLinkScheme)://topic/\(tip.topicSlug)"))
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.title)
                .foregroundStyle(.white.opacity(0.7))

            VStack(alignment: .leading, spacing: 4) {
                Text("Daily Coaching Tip")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Open BetterOne to get your first insight.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.systemIndigo).gradient)
    }
}

// MARK: - Source Display Label

extension CoachingTip.TipSource {
    var displayLabel: String {
        switch self {
        case .heuristic: "Daily Tip"
        case .coreIdea: "Core Insight"
        case .sessionTakeaway: "Your Takeaway"
        }
    }
}
