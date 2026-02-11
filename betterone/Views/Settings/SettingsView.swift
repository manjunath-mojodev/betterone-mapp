import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(SubscriptionService.self) private var subscriptionService
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    
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

            Section("Creator") {
                NavigationLink {
                    CreatorModeGateView()
                } label: {
                    Label("Creator Mode", systemImage: "lock.shield")
                }
            }


            
            Section("Development") {
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
