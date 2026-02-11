import SwiftUI
import SwiftData

struct GuardrailDashboardView: View {
    @Query(sort: \GuardrailLog.timestamp, order: .reverse) private var logs: [GuardrailLog]

    var body: some View {
        Group {
            if logs.isEmpty {
                ContentUnavailableView(
                    "No Guardrail Events",
                    systemImage: "shield.checkered",
                    description: Text("Boundary approaches during coaching sessions will appear here.")
                )
            } else {
                List(logs) { log in
                    GuardrailLogRow(log: log)
                }
            }
        }
        .navigationTitle("Guardrail Dashboard")
    }
}

private struct GuardrailLogRow: View {
    let log: GuardrailLog
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack {
                Text(log.ruleTitle ?? "General boundary")
                    .font(Theme.headlineFont)
                Spacer()
                Text(log.triggerType == "rule_based" ? "Rule" : "LLM")
                    .font(Theme.badgeFont)
                    .padding(.horizontal, Theme.badgePaddingH)
                    .padding(.vertical, Theme.badgePaddingV)
                    .background(Theme.accent.opacity(Theme.opacitySubtle))
                    .clipShape(Capsule())
            }

            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: Theme.spacingSM) {
                    Text("User: \(log.userMessageExcerpt)")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textSecondary)

                    Text("Response: \(log.assistantResponse)")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textSecondary)
                }
            } label: {
                Text(log.userMessageExcerpt.truncated(to: 60))
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }

            Text(log.timestamp.relativeFormatted)
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.vertical, Theme.spacingXS)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(log.ruleTitle ?? "Boundary") event, \(log.triggerType == "rule_based" ? "rule based" : "LLM detected"), \(log.timestamp.relativeFormatted)")
    }
}
