import SwiftUI
import SwiftData

struct RulesEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Rule.priority) private var rules: [Rule]
    @State private var showAddSheet = false

    var body: some View {
        Group {
            if rules.isEmpty {
                ContentUnavailableView(
                    "No Rules",
                    systemImage: "list.bullet.clipboard",
                    description: Text("Add rules to guide how the AI coach behaves.")
                )
            } else {
                List {
                    ForEach(rules) { rule in
                        VStack(alignment: .leading, spacing: Theme.spacingXS) {
                            HStack {
                                Text(rule.title)
                                    .font(Theme.headlineFont)
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { rule.isActive },
                                    set: { newValue in
                                        rule.isActive = newValue
                                        rule.updatedAt = Date()
                                    }
                                ))
                                .labelsHidden()
                                .accessibilityLabel("\(rule.title) active")
                            }

                            Text(rule.content)
                                .font(Theme.captionFont)
                                .foregroundStyle(Theme.textSecondary)

                            Text(rule.category.capitalized)
                                .font(Theme.badgeFont)
                                .padding(.horizontal, Theme.badgePaddingH)
                                .padding(.vertical, Theme.badgePaddingV)
                                .background(Theme.accent.opacity(Theme.opacitySubtle))
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, Theme.spacingXS)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(rule.title), \(rule.category), \(rule.isActive ? "active" : "inactive")")
                        .accessibilityHint(rule.content)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            modelContext.delete(rules[index])
                        }
                    }
                }
            }
        }
        .navigationTitle("Rules of Engagement")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add new rule")
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddRuleSheet { title, content, category in
                let maxPriority = rules.map(\.priority).max() ?? 0
                let rule = Rule(title: title, content: content, category: category, priority: maxPriority + 1)
                modelContext.insert(rule)
                showAddSheet = false
            }
        }
    }
}

struct AddRuleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var category = "behavior"
    let onSave: (String, String, String) -> Void

    private let categories = ["behavior", "tone", "boundary", "scope"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                    .accessibilityLabel("Rule title")
                TextField("Rule content", text: $content, axis: .vertical)
                    .lineLimit(3...6)
                    .accessibilityLabel("Rule description")
                Picker("Category", selection: $category) {
                    ForEach(categories, id: \.self) { cat in
                        Text(cat.capitalized).tag(cat)
                    }
                }
            }
            .navigationTitle("New Rule")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !title.isEmpty, !content.isEmpty else { return }
                        onSave(title, content, category)
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
    }
}
