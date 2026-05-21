import '../entities/entities.dart';

/// Orchestrates Google Play billing and server verification for support.
abstract class SupportRepository {
  Future<bool> isBillingAvailable();

  Future<List<SupportProduct>> getSupportProducts();

  Future<PurchaseOutcome> purchaseSupportProduct(String productId);

  Future<void> restorePurchases();

  Stream<PurchaseOutcome> get watchVerifiedPurchases;

  Future<DateTime?> getLastSupportAt();

  Future<String?> getLastSupportProductId();
}
