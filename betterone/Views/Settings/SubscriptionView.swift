import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(SubscriptionService.self) private var subscriptionService

    var body: some View {
        List {
            currentStatusSection

            if subscriptionService.isSubscribed {
                manageSection
            } else {
                plansSection
                restoreSection
            }
        }
        .navigationTitle("Subscription")
    }

    // MARK: - Current Status

    private var currentStatusSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Plan")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textSecondary)
                    Text(subscriptionService.currentTier.displayName)
                        .font(Theme.titleFont)
                }
                Spacer()
                Image(systemName: subscriptionService.isSubscribed ? "checkmark.seal.fill" : "person.crop.circle")
                    .font(.title)
                    .foregroundStyle(subscriptionService.isSubscribed ? Theme.accent : Theme.textSecondary)
            }
            .padding(.vertical, Theme.spacingSM)

            if !subscriptionService.isSubscribed {
                Text("You have \(subscriptionService.freeSessionLimit) free coaching sessions. Upgrade for unlimited access.")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    // MARK: - Plans

    private var plansSection: some View {
        Section("Choose a Plan") {
            if subscriptionService.availableProducts.isEmpty {
                VStack(spacing: Theme.spacingSM) {
                    ProgressView()
                    Text("Loading plans...")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.spacingMD)
            } else {
                ForEach(subscriptionService.availableProducts, id: \.id) { product in
                    PlanRow(product: product)
                }
            }

            if let error = subscriptionService.errorMessage {
                Text(error)
                    .font(Theme.captionFont)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Manage

    private var manageSection: some View {
        Section("Manage") {
            Text("Your premium subscription is active. Thank you for supporting \(AppConstants.creatorName)!")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textSecondary)

            Button("Manage in App Store") {
                Task {
                    if let windowScene = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene }).first {
                        try? await AppStore.showManageSubscriptions(in: windowScene)
                    }
                }
            }
        }
    }

    // MARK: - Restore

    private var restoreSection: some View {
        Section {
            Button("Restore Purchases") {
                Task {
                    await subscriptionService.restorePurchases()
                }
            }
            .font(Theme.bodyFont)
        }
    }
}

// MARK: - Plan Row

private struct PlanRow: View {
    let product: Product
    @Environment(SubscriptionService.self) private var subscriptionService

    private var isYearly: Bool {
        product.id == SubscriptionService.premiumYearlyId
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(isYearly ? "Yearly" : "Monthly")
                        .font(Theme.bodyFont.bold())
                    if isYearly {
                        Text("Best Value")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Theme.accent, in: Capsule())
                    }
                }
                Text(product.displayPrice + (isYearly ? "/year" : "/month"))
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Button {
                Task {
                    await subscriptionService.purchase(product)
                }
            } label: {
                if subscriptionService.purchaseInProgress {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Subscribe")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(subscriptionService.purchaseInProgress)
        }
        .padding(.vertical, 4)
    }
}
