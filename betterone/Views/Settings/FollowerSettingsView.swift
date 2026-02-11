import SwiftUI
import SwiftData

struct FollowerSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()
    @State private var showSaved = false

    var body: some View {
        Form {
            Section("Focus Areas") {
                ForEach(AppConstants.helpAreas, id: \.self) { area in
                    Toggle(area, isOn: Binding(
                        get: { viewModel.selectedHelpAreas.contains(area) },
                        set: { isOn in
                            if isOn {
                                viewModel.selectedHelpAreas.insert(area)
                            } else {
                                viewModel.selectedHelpAreas.remove(area)
                            }
                        }
                    ))
                    .accessibilityLabel("\(area) focus area")
                }
            }

            Section("Feedback Style") {
                Picker("Style", selection: $viewModel.feedbackStyle) {
                    Text("Gentle & reflective").tag("gentle")
                    Text("Direct & practical").tag("direct")
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Feedback style preference")
            }

            Section("Notes") {
                TextField("Anything we should know...", text: $viewModel.optionalNote, axis: .vertical)
                    .lineLimit(3...6)
                    .accessibilityLabel("Additional context note")
            }

            Section {
                Button("Save Changes") {
                    viewModel.saveProfile(modelContext: modelContext)
                    showSaved = true
                }
                .disabled(viewModel.profile == nil)
                .accessibilityHint("Save your profile changes")
            }
        }
        .navigationTitle("Your Profile")
        .onAppear {
            viewModel.loadProfile(modelContext: modelContext)
        }
        .overlay(alignment: .bottom) {
            if showSaved {
                Label("Saved", systemImage: "checkmark.circle.fill")
                    .font(Theme.headlineFont)
                    .padding(.horizontal, Theme.spacingLG)
                    .padding(.vertical, Theme.spacingSM)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, Theme.spacingLG)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .accessibilityLabel("Changes saved successfully")
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Theme.toastDuration) {
                            withAnimation { showSaved = false }
                        }
                    }
            }
        }
        .animation(Theme.animationDefault, value: showSaved)
    }
}
