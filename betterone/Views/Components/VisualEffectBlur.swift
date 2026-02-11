import SwiftUI
import UIKit

/// A custom frosted glass blur effect using UIVisualEffectView.
/// Unlike SwiftUI's material modifiers, this allows control over
/// the blur intensity via the view's alpha, creating a truly
/// translucent frosted glass appearance.
struct FrostedGlassView: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    var blurAlpha: CGFloat
    
    init(style: UIBlurEffect.Style = .light, alpha: CGFloat = 0.85) {
        self.blurStyle = style
        self.blurAlpha = alpha
    }
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        let blurEffect = UIBlurEffect(style: blurStyle)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.alpha = blurAlpha
        blurView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            blurView.topAnchor.constraint(equalTo: containerView.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let blurView = uiView.subviews.first as? UIVisualEffectView {
            blurView.effect = UIBlurEffect(style: blurStyle)
            blurView.alpha = blurAlpha
        }
    }
}
