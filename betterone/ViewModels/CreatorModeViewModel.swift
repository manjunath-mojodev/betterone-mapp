import SwiftUI
import SwiftData

@Observable
final class CreatorModeViewModel {
    var persona: PersonaIdentity?
    var rules: [Rule] = []
    var guardrailLogs: [GuardrailLog] = []
    var isAuthenticated: Bool = false
    var passcodeInput: String = ""

    func authenticate() -> Bool {
        let success = passcodeInput == AppConstants.creatorModePasscode
        isAuthenticated = success
        return success
    }

    func loadData(modelContext: ModelContext) {
        let personaDescriptor = FetchDescriptor<PersonaIdentity>()
        persona = try? modelContext.fetch(personaDescriptor).first

        let rulesDescriptor = FetchDescriptor<Rule>(sortBy: [SortDescriptor(\.priority)])
        rules = (try? modelContext.fetch(rulesDescriptor)) ?? []

        let logsDescriptor = FetchDescriptor<GuardrailLog>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        guardrailLogs = (try? modelContext.fetch(logsDescriptor)) ?? []
    }

    func toggleRule(_ rule: Rule) {
        rule.isActive.toggle()
        rule.updatedAt = Date()
    }

    func addRule(title: String, content: String, category: String, modelContext: ModelContext) {
        let maxPriority = rules.map(\.priority).max() ?? 0
        let rule = Rule(title: title, content: content, category: category, priority: maxPriority + 1)
        modelContext.insert(rule)
        rules.append(rule)
    }

    func deleteRule(_ rule: Rule, modelContext: ModelContext) {
        rules.removeAll { $0.id == rule.id }
        modelContext.delete(rule)
    }
}
