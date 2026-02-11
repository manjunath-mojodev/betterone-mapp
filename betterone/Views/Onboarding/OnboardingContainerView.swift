import SwiftUI

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var viewModel = OnboardingViewModel()

    private let totalSteps = 3

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: Theme.spacingSM) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step <= viewModel.currentStep ? Theme.accent : Theme.accent.opacity(Theme.opacitySubtle))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, Theme.spacingLG)
            .padding(.top, Theme.spacingSM)
            .animation(Theme.animationDefault, value: viewModel.currentStep)
            .accessibilityLabel("Step \(viewModel.currentStep + 1) of \(totalSteps)")

            Group {
                switch viewModel.currentStep {
                case 0:
                    WelcomeView {
                        withAnimation { viewModel.currentStep = 1 }
                    }
                    .transition(.push(from: .trailing))
                case 1:
                    ContextCaptureView(viewModel: viewModel) {
                        withAnimation { viewModel.currentStep = 2 }
                    }
                    .transition(.push(from: .trailing))
                default:
                    ConfirmationView(viewModel: viewModel) {
                        viewModel.completeOnboarding(modelContext: modelContext, appState: appState)
                    }
                    .transition(.push(from: .trailing))
                }
            }
        }
    }
}
