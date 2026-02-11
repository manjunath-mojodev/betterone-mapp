import SwiftUI

struct CreatorModeGateView: View {
    @State private var viewModel = CreatorModeViewModel()
    @State private var showError = false
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        if viewModel.isAuthenticated {
            CreatorModeView(viewModel: viewModel)
        } else {
            VStack(spacing: Theme.spacingLG) {
                Spacer()

                Image(systemName: "lock.shield")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.accent)

                Text("Creator Mode")
                    .font(Theme.titleFont)

                Text("Enter your passcode to access creator tools.")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: Theme.spacingSM) {
                    SecureField("Passcode", text: $viewModel.passcodeInput)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)
                        .multilineTextAlignment(.center)
                        .offset(x: shakeOffset)
                        .onSubmit { attemptUnlock() }

                    if showError {
                        Text("Incorrect passcode. Try again.")
                            .font(Theme.captionFont)
                            .foregroundStyle(.red)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                Button("Unlock") {
                    attemptUnlock()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.passcodeInput.isEmpty)

                Spacer()
            }
            .padding(Theme.spacingLG)
            .navigationTitle("Creator Mode")
            .animation(.default, value: showError)
        }
    }

    private func attemptUnlock() {
        let success = viewModel.authenticate()
        if !success {
            showError = true
            viewModel.passcodeInput = ""
            // Shake animation
            withAnimation(.default) {
                shakeOffset = 10
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.default) {
                    shakeOffset = -10
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.default) {
                    shakeOffset = 0
                }
            }
        }
    }
}
