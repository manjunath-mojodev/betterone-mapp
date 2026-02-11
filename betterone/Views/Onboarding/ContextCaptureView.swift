import SwiftUI

struct ContextCaptureView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingLG) {
                Text("A little context goes a long way")
                    .font(Theme.titleFont)

                // Help Areas
                VStack(alignment: .leading, spacing: Theme.spacingSM) {
                    Text("What do you want help with right now?")
                        .font(Theme.headlineFont)

                    FlowLayout(spacing: Theme.spacingSM) {
                        ForEach(AppConstants.helpAreas, id: \.self) { area in
                            PillButton(
                                title: area,
                                isSelected: viewModel.selectedHelpAreas.contains(area)
                            ) {
                                if viewModel.selectedHelpAreas.contains(area) {
                                    viewModel.selectedHelpAreas.remove(area)
                                } else {
                                    viewModel.selectedHelpAreas.insert(area)
                                }
                            }
                            .accessibilityLabel(area)
                            .accessibilityAddTraits(viewModel.selectedHelpAreas.contains(area) ? .isSelected : [])
                        }
                    }
                }

                // Feedback Style
                VStack(alignment: .leading, spacing: Theme.spacingSM) {
                    Text("How do you prefer feedback?")
                        .font(Theme.headlineFont)

                    HStack(spacing: Theme.spacingSM) {
                        feedbackButton(title: "Gentle & reflective", value: "gentle")
                        feedbackButton(title: "Direct & practical", value: "direct")
                    }
                }

                // Optional Note
                VStack(alignment: .leading, spacing: Theme.spacingSM) {
                    Text("Anything else? (optional)")
                        .font(Theme.headlineFont)

                    TextField("e.g., I'm going through a career change...", text: $viewModel.optionalNote, axis: .vertical)
                        .lineLimit(3...6)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Additional context")
                }

                Button(action: onContinue) {
                    Text("Continue")
                        .font(Theme.headlineFont)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.spacingMD)
                        .background(viewModel.canProceedFromContext ? Theme.accent : Theme.secondaryBackground)
                        .foregroundStyle(viewModel.canProceedFromContext ? .white : Theme.textSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                }
                .disabled(!viewModel.canProceedFromContext)
                .accessibilityHint(viewModel.canProceedFromContext ? "Proceed to confirmation" : "Select at least one focus area first")
            }
            .padding(Theme.spacingLG)
        }
    }

    private func feedbackButton(title: String, value: String) -> some View {
        Button {
            viewModel.feedbackStyle = value
        } label: {
            Text(title)
                .font(Theme.bodyFont)
                .frame(maxWidth: .infinity)
                .padding(Theme.spacingSM)
                .background(viewModel.feedbackStyle == value ? Theme.accent : Theme.secondaryBackground)
                .foregroundStyle(viewModel.feedbackStyle == value ? .white : Theme.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSM))
        }
        .accessibilityLabel(title)
        .accessibilityAddTraits(viewModel.feedbackStyle == value ? .isSelected : [])
    }
}

// Simple flow layout for pill buttons
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxWidth = max(maxWidth, x)
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
