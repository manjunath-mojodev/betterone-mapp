import SwiftUI
import Combine

struct LoadingIndicator: View {
    @State private var dotCount = 0
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: Theme.spacingXS) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Theme.textSecondary)
                    .frame(width: 6, height: 6)
                    .opacity(index <= dotCount ? 1 : Theme.opacityDisabled)
            }
        }
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 3
        }
        .accessibilityLabel("Loading")
        .accessibilityHidden(false)
    }
}
