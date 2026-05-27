import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/features/premium/domain/services/subscription_catalog_prefetch.dart';

@lazySingleton
class FirebaseInitializationService {
  FirebaseInitializationService(this._subscriptionCatalogPrefetch);

  final SubscriptionCatalogPrefetch _subscriptionCatalogPrefetch;

  /// Initialize read-only Firebase data (e.g. cache subscription plans).
  ///
  /// This method must NOT write to Firestore from the client. Catalog
  /// seeding belongs in an admin backend or migration script.
  ///
  /// Startup skips this path when launch config
  /// `subscriptionServiceEnabled` is false (default).
  Future<void> initializeFirebaseData() async {
    try {
      logger.d('Initializing Firebase data (read-only)...');

      // Pre-fetch subscription plans so they are cached for offline use.
      await _subscriptionCatalogPrefetch.prefetch();

      logger.d('Firebase data initialization completed');
    } catch (e) {
      logger.d('Warning: Could not initialize Firebase data: $e');
    }
  }
}
