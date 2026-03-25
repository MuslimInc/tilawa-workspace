import '../../features/premium/data/services/subscription_plans_service.dart';
import 'package:tilawa/core/logging/app_logger.dart';

class FirebaseInitializationService {
  FirebaseInitializationService({
    required SubscriptionPlansService subscriptionPlansService,
  }) : _subscriptionPlansService = subscriptionPlansService;
  final SubscriptionPlansService _subscriptionPlansService;

  /// Initialize read-only Firebase data (e.g. cache subscription plans).
  ///
  /// This method must NOT write to Firestore from the client. Catalog
  /// seeding belongs in an admin backend or migration script.
  Future<void> initializeFirebaseData() async {
    try {
      logger.d('Initializing Firebase data (read-only)...');

      // Pre-fetch subscription plans so they are cached for offline use.
      await _subscriptionPlansService.getSubscriptionPlans();

      logger.d('Firebase data initialization completed');
    } catch (e) {
      logger.d('Warning: Could not initialize Firebase data: $e');
    }
  }
}
