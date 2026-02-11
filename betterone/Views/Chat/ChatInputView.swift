import SwiftUI

struct ChatInputView: View {
    @Binding var text: String
    let isDisabled: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: Theme.spacingSM) {
            ZStack(alignment: .topLeading) {
                GrowingTextView(text: $text, placeholder: "Type a message...")
                    .frame(minHeight: 36, maxHeight: 120)
                    .accessibilityLabel("Message input")
                    .accessibilityHint("Type your message to \(AppConstants.creatorName)")
            }
            .background(Theme.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))

            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(canSend ? Theme.accent : Theme.textSecondary.opacity(Theme.opacityDisabled))
            }
            .disabled(!canSend)
            .padding(.bottom, Theme.spacingSM)
            .accessibilityLabel("Send message")
            .accessibilityHint(canSend ? "Send your message" : "Type a message first")
        }
        .padding(.horizontal, Theme.spacingMD)
        .padding(.vertical, Theme.spacingSM)
    }

    private var canSend: Bool {
        !isDisabled && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - UIKit-backed text view for reliable emoji/paste support

struct GrowingTextView: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        textView.isScrollEnabled = true
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Placeholder label
        let label = UILabel()
        label.text = placeholder
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textColor = UIColor.secondaryLabel.withAlphaComponent(0.4)
        label.tag = 999
        label.translatesAutoresizingMaskIntoConstraints = false
        textView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 13),
            label.topAnchor.constraint(equalTo: textView.topAnchor, constant: 10)
        ])

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != text {
            textView.text = text
        }
        if let label = textView.viewWithTag(999) as? UILabel {
            label.isHidden = !text.isEmpty
        }
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: GrowingTextView

        init(_ parent: GrowingTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            if let label = textView.viewWithTag(999) as? UILabel {
                label.isHidden = !textView.text.isEmpty
            }
        }
    }
}
