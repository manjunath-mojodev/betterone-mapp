import Foundation
import RevenueCat

/// Subscription tiers for the app
enum SubscriptionTier: String, CaseIterable {
    case free = "free"
    case premium = "premium"

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Premium"
        }
    }
}

/// Entitlement identifier configured in RevenueCat dashboard
private enum RevenueCatConstants {
    static let premiumEntitlementId = "premium"
}

/// Subscription service using RevenueCat.
@Observable
final class SubscriptionService: NSObject {
    // MARK: - Product IDs

    static let premiumMonthlyId = "com.betterone.premium.monthly"
    static let premiumYearlyId = "com.betterone.premium.yearly"

    // MARK: - State

    private(set) var actualTier: SubscriptionTier = .free
    var overrideTier: SubscriptionTier?
    var currentTier: SubscriptionTier { overrideTier ?? actualTier }
    var isSubscribed: Bool { currentTier == .premium }
    var availablePackages: [RevenueCat.Package] = []
    var purchaseInProgress = false
    var errorMessage: String?

    /// Free users have unlimited sessions; premium gates topics, not sessions.
    var canAlwaysStartSession: Bool { true }

    // MARK: - Lifecycle

    func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Secrets.revenueCatAPIKey)
        Purchases.shared.delegate = self

        Task { [weak self] in
            await self?.loadOfferings()
            await self?.checkEntitlements()
        }
    }

    // MARK: - Offerings

    func loadOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            if let current = offerings.current {
                availablePackages = current.availablePackages
            }
        } catch {
            errorMessage = "Failed to load subscription options."
        }
    }

    // MARK: - Purchase

    func purchase(_ package: RevenueCat.Package) async {
        purchaseInProgress = true
        errorMessage = nil

        do {
            let result = try await Purchases.shared.purchase(package: package)

            if !result.userCancelled {
                updateTier(from: result.customerInfo)
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }

        purchaseInProgress = false
    }

    // MARK: - Restore

    func restorePurchases() async {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            updateTier(from: customerInfo)
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Entitlement Check

    func checkEntitlements() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateTier(from: customerInfo)
        } catch {
            actualTier = .free
        }
    }

    /// Free users can always start sessions. Premium gates topics, not session count.
    func canStartSession(currentSessionCount: Int) -> Bool {
        return true
    }

    // MARK: - Private

    private func updateTier(from customerInfo: CustomerInfo) {
        let hasPremium = customerInfo.entitlements[RevenueCatConstants.premiumEntitlementId]?.isActive == true
        actualTier = hasPremium ? .premium : .free
    }
}

// MARK: - PurchasesDelegate

extension SubscriptionService: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.updateTier(from: customerInfo)
        }
    }
}
