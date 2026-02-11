import Foundation
import StoreKit

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

/// Subscription service using StoreKit 2.
/// Designed with a RevenueCat-compatible interface for easy migration.
@Observable
final class SubscriptionService {
    // MARK: - Product IDs

    /// Configure these in App Store Connect
    static let premiumMonthlyId = "com.betterone.premium.monthly"
    static let premiumYearlyId = "com.betterone.premium.yearly"
    private static let productIds: Set<String> = [premiumMonthlyId, premiumYearlyId]

    // MARK: - State

    var currentTier: SubscriptionTier = .free
    var isSubscribed: Bool { currentTier == .premium }
    var availableProducts: [Product] = []
    var purchaseInProgress = false
    var errorMessage: String?

    /// Number of free sessions allowed before paywall
    let freeSessionLimit = 3

    private var updateListenerTask: Task<Void, Never>?

    // MARK: - Lifecycle

    func configure() {
        updateListenerTask = Task { [weak self] in
            guard let self else { return }
            await self.listenForTransactionUpdates()
        }

        Task { [weak self] in
            await self?.loadProducts()
            await self?.checkEntitlements()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Products

    func loadProducts() async {
        do {
            let products = try await Product.products(for: Self.productIds)
            availableProducts = products.sorted { $0.price < $1.price }
        } catch {
            errorMessage = "Failed to load subscription options."
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        purchaseInProgress = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await checkEntitlements()

            case .userCancelled:
                break

            case .pending:
                errorMessage = "Purchase is pending approval."

            @unknown default:
                break
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }

        purchaseInProgress = false
    }

    // MARK: - Restore

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkEntitlements()
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Entitlement Check

    func checkEntitlements() async {
        var hasPremium = false

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if Self.productIds.contains(transaction.productID) {
                    hasPremium = true
                }
            }
        }

        currentTier = hasPremium ? .premium : .free
    }

    /// Check how many sessions the user has used (called externally with a count)
    func canStartSession(currentSessionCount: Int) -> Bool {
        if isSubscribed { return true }
        return currentSessionCount < freeSessionLimit
    }

    // MARK: - Transaction Updates

    private func listenForTransactionUpdates() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result) {
                await transaction.finish()
                await checkEntitlements()
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
