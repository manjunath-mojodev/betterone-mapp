import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(SubscriptionService.self) private var subscriptionService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingLG) {
                    // Header
                    VStack(spacing: Theme.spacingSM) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.yellow)

                        Text("Unlock Premium")
                            .font(.title.bold())

                        Text("Get unlimited access to all coaching topics, advanced insights, and more.")
                            .font(Theme.bodyFont)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Theme.spacingXL)

                    // Features
                    VStack(alignment: .leading, spacing: Theme.spacingMD) {
                        FeatureRow(icon: "checkmark.circle.fill", text: "All coaching topics unlocked")
                        FeatureRow(icon: "infinity", text: "Unlimited coaching sessions")
                        FeatureRow(icon: "sparkles", text: "Priority AI responses")
                    }
                    .padding(.horizontal, Theme.spacingLG)

                    // Plans
                    if subscriptionService.availablePackages.isEmpty {
                        ProgressView()
                            .padding(.vertical, Theme.spacingLG)
                    } else {
                        VStack(spacing: Theme.spacingSM) {
                            ForEach(subscriptionService.availablePackages, id: \.identifier) { package in
                                PaywallPlanButton(package: package)
                            }
                        }
                        .padding(.horizontal, Theme.spacingLG)
                    }

                    if let error = subscriptionService.errorMessage {
                        Text(error)
                            .font(Theme.captionFont)
                            .foregroundStyle(.red)
                    }

                    // Free option
                    Button {
                        dismiss()
                    } label: {
                        Text("Continue with limited access")
                            .font(Theme.bodyFont)
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.spacingSM)
                    }

                    // Restore
                    Button("Restore Purchases") {
                        Task {
                            await subscriptionService.restorePurchases()
                            if subscriptionService.isSubscribed {
                                dismiss()
                            }
                        }
                    }
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textSecondary)
                }
                .padding(.bottom, Theme.spacingXL)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .frame(width: 30, height: 30)
                            .background(Theme.secondaryBackground)
                            .clipShape(Circle())
                    }
                }
            }
            .onChange(of: subscriptionService.isSubscribed) { _, isSubscribed in
                if isSubscribed { dismiss() }
            }
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Theme.spacingSM) {
            Image(systemName: icon)
                .foregroundStyle(Theme.accent)
                .frame(width: 24)
            Text(text)
                .font(Theme.bodyFont)
        }
    }
}

private struct PaywallPlanButton: View {
    let package: RevenueCat.Package
    @Environment(SubscriptionService.self) private var subscriptionService

    private var isYearly: Bool {
        package.packageType == .annual
    }

    var body: some View {
        Button {
            Task {
                await subscriptionService.purchase(package)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(isYearly ? "Yearly" : "Monthly")
                            .font(Theme.bodyFont.bold())
                        if isYearly {
                            Text("Best Value")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.accent, in: Capsule())
                        }
                    }
                    Text(package.storeProduct.localizedPriceString + (isYearly ? "/year" : "/month"))
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                if subscriptionService.purchaseInProgress {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Subscribe")
                        .font(Theme.bodyFont.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.spacingMD)
                        .padding(.vertical, Theme.spacingSM)
                        .background(Theme.accent, in: Capsule())
                }
            }
            .padding(Theme.spacingMD)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        }
        .buttonStyle(.plain)
        .disabled(subscriptionService.purchaseInProgress)
    }
}
