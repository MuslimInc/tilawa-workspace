/// Warms subscription plan catalog data (e.g. Firestore cache) at startup.
abstract class SubscriptionCatalogPrefetch {
  Future<void> prefetch();
}
