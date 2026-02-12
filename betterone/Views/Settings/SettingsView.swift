import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(SubscriptionService.self) private var subscriptionService
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview

    @State private var showResetConfirmation = false

    var body: some View {
        List {
            Section("Your Profile") {
                NavigationLink {
                    FollowerSettingsView()
                } label: {
                    Label("Update Profile", systemImage: "person.crop.circle")
                }
            }

            Section("Subscription") {
                NavigationLink {
                    SubscriptionView()
                } label: {
                    Label {
                        HStack {
                            Text("Manage Subscription")
                            Spacer()
                            Text(subscriptionService.currentTier.displayName)
                                .font(Theme.captionFont)
                                .foregroundStyle(subscriptionService.isSubscribed ? Theme.accent : Theme.textSecondary)
                        }
                    } icon: {
                        Image(systemName: subscriptionService.isSubscribed ? "checkmark.seal.fill" : "creditcard")
                    }
                }
            }

            Section("Widget") {
                NavigationLink {
                    WidgetSetupGuideView()
                } label: {
                    Label("Set Up Home Screen Widget", systemImage: "rectangle.on.rectangle")
                }
            }

            Section("Support") {
                Button {
                    requestReview()
                } label: {
                    Label("Rate Us on the App Store", systemImage: "star.fill")
                }
            }

            if AppConstants.isDevelopmentBuild {
                Section("Development") {
                    NavigationLink {
                        CreatorModeView(viewModel: CreatorModeViewModel(isAuthenticated: true))
                    } label: {
                        Label("Creator Mode", systemImage: "hammer")
                    }

                    Toggle(isOn: premiumOverrideBinding) {
                        Label("Simulate Premium", systemImage: "crown")
                    }

                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                    }

                    Button(role: .destructive) {
                        hardReset()
                    } label: {
                        Label("Hard Reset (All Data)", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Reset Onboarding?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetOnboarding()
            }
        } message: {
            Text("This will delete your profile and restart the onboarding process. This action cannot be undone.")
        }
    }
    
    private func resetOnboarding() {
        do {
            let profiles = try modelContext.fetch(FetchDescriptor<FollowerProfile>())
            for profile in profiles {
                modelContext.delete(profile)
            }
            appState.onboardingComplete = false
        } catch {
            print("Failed to reset onboarding: \(error)")
        }
    }
    
    private var premiumOverrideBinding: Binding<Bool> {
        Binding(
            get: { subscriptionService.overrideTier == .premium },
            set: { subscriptionService.overrideTier = $0 ? .premium : nil }
        )
    }

    private func hardReset() {
        do {
            // Delete Profiles
            let profiles = try modelContext.fetch(FetchDescriptor<FollowerProfile>())
            for profile in profiles { modelContext.delete(profile) }
            
            // Delete Topics
            let topics = try modelContext.fetch(FetchDescriptor<Topic>())
            for topic in topics { modelContext.delete(topic) }
            
            // Delete Sessions
            let sessions = try modelContext.fetch(FetchDescriptor<ChatSession>())
            for session in sessions { modelContext.delete(session) }
            
            appState.onboardingComplete = false
        } catch {
            print("Failed to perform hard reset: \(error)")
        }
    }
}
