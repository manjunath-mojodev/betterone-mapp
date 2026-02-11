import SwiftUI
import SwiftData

struct CreatorModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: CreatorModeViewModel

    var body: some View {
        List {
            if let persona = viewModel.persona {
                Section {
                    HStack(spacing: Theme.spacingSM) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title)
                            .foregroundStyle(Theme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(persona.name)
                                .font(Theme.bodyFont.bold())
                            Text("Creator")
                                .font(Theme.captionFont)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Persona & Rules") {
                NavigationLink {
                    PersonaTuningView()
                } label: {
                    Label("Persona Tuning", systemImage: "theatermasks")
                }
                NavigationLink {
                    RulesEditorView()
                } label: {
                    Label("Rules of Engagement", systemImage: "list.bullet.clipboard")
                }
            }

            Section("Testing") {
                NavigationLink {
                    ResponseSandboxView()
                } label: {
                    Label("Response Sandbox", systemImage: "text.bubble")
                }
            }

            Section("Trust & Safety") {
                NavigationLink {
                    GuardrailDashboardView()
                } label: {
                    Label("Guardrail Dashboard", systemImage: "shield.checkered")
                }

                if !viewModel.guardrailLogs.isEmpty {
                    LabeledContent("Total Events", value: "\(viewModel.guardrailLogs.count)")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .navigationTitle("Creator Mode")
        .onAppear {
            viewModel.loadData(modelContext: modelContext)
        }
    }
}
