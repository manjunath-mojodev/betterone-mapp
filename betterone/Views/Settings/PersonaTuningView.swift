import SwiftUI
import SwiftData

struct PersonaTuningView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var personas: [PersonaIdentity]

    private var persona: PersonaIdentity? { personas.first }

    var body: some View {
        Form {
            if let persona {
                Section {
                    Label(persona.voice, systemImage: "waveform")
                } header: {
                    Text("Voice")
                }

                Section {
                    Label(persona.tone, systemImage: "music.note")
                } header: {
                    Text("Tone")
                }

                Section {
                    Label(persona.coachingStyle, systemImage: "figure.mind.and.body")
                } header: {
                    Text("Coaching Style")
                }

                Section("Core Beliefs") {
                    ForEach(persona.coreBeliefs, id: \.self) { belief in
                        Label(belief, systemImage: "heart")
                            .font(Theme.bodyFont)
                    }
                }

                Section {
                    Label(persona.riskStance, systemImage: "shield")
                } header: {
                    Text("Risk Stance")
                }

                Section("Boundaries") {
                    ForEach(persona.boundaries, id: \.self) { boundary in
                        Label(boundary, systemImage: "exclamationmark.octagon")
                            .font(Theme.bodyFont)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Persona",
                    systemImage: "person.crop.circle.badge.questionmark",
                    description: Text("Persona data will load on first launch.")
                )
            }
        }
        .navigationTitle("Persona")
    }
}
