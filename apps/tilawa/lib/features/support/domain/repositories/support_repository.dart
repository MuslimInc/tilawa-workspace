import '../entities/entities.dart';

/// Orchestrates Google Play billing and server verification for support.
abstract class SupportRepository {
  Future<bool> isBillingAvailable();

  Future<List<SupportProduct>> getSupportProducts();

  /// Drains stale Play purchases; cancels abandoned waiters when [resetWaiters].
  Future<void> prepareSupportSession({bool resetWaiters = true});

  /// Aborts the in-flight purchase for [productId] (if any) with
  /// "billing unavailable", so the UI can recover from a closed Play sheet
  /// that didn't emit a stream event. Returns `true` if a waiter was aborted.
  bool abortPendingPurchaseAsUnavailable(String productId);

  Future<PurchaseOutcome> purchaseSupportProduct(String productId);

  Future<void> restorePurchases();

  Stream<PurchaseOutcome> get watchVerifiedPurchases;

  Future<DateTime?> getLastSupportAt();

  Future<String?> getLastSupportProductId();
}
