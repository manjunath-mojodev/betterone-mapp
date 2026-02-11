import SwiftUI

enum Theme {
    // MARK: - Colors
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let accent = Color(.systemIndigo)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let userBubble = Color(.systemIndigo)
    static let assistantBubble = Color(.secondarySystemBackground)
    static let cardBackground = Color(.secondarySystemBackground)
    static let success = Color(.systemGreen)
    static let warning = Color(.systemOrange)
    static let error = Color(.systemRed)

    // MARK: - Spacing
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32

    // MARK: - Corner Radius
    static let cornerRadius: CGFloat = 12
    static let cornerRadiusSM: CGFloat = 8
    static let cornerRadiusMD: CGFloat = 12

    // MARK: - Icon Sizes
    static let iconSizeSM: CGFloat = 8
    static let iconSizeMD: CGFloat = 24
    static let iconSizeLG: CGFloat = 44
    static let iconSizeXL: CGFloat = 60

    // MARK: - Opacity
    static let opacitySubtle: Double = 0.1
    static let opacityDisabled: Double = 0.4
    static let opacityOverlay: Double = 0.6

    // MARK: - Animation
    static let animationDefault: Animation = .easeInOut(duration: 0.25)
    static let toastDuration: TimeInterval = 1.5

    // MARK: - Fonts
    static let titleFont = Font.title2.weight(.semibold)
    static let headlineFont = Font.headline
    static let bodyFont = Font.body
    static let captionFont = Font.caption
    static let framingFont = Font.subheadline.italic()

    // MARK: - Badge
    static let badgePaddingH: CGFloat = 8
    static let badgePaddingV: CGFloat = 2
    static let badgeFont = Font.caption2
}
