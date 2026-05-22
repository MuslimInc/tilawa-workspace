import '../entities/entities.dart';

/// Orchestrates Google Play billing and server verification for support.
abstract class SupportRepository {
  Future<bool> isBillingAvailable();

  Future<List<SupportProduct>> getSupportProducts();

  /// Drains stale Play purchases; cancels abandoned waiters when [resetWaiters].
  Future<void> prepareSupportSession({bool resetWaiters = true});

  Future<PurchaseOutcome> purchaseSupportProduct(String productId);

  Future<void> restorePurchases();

  Stream<PurchaseOutcome> get watchVerifiedPurchases;

  Future<DateTime?> getLastSupportAt();

  Future<String?> getLastSupportProductId();
}
