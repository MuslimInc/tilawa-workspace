import 'package:cloud_firestore/cloud_firestore.dart';

// No FirebaseAuth dependency required here
import 'package:tilawa_core/config/currency_config.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import '../../domain/entities/subscription_plan.dart';

class SubscriptionPlansService {
  SubscriptionPlansService({
    required this._firestore,
    this.firestoreCatalogEnabled = true,
  });

  final FirebaseFirestore _firestore;

  /// When false, no subscription-related Firestore reads or writes run from
  /// this service (catalog defaults, premium status, purchase records).
  final bool firestoreCatalogEnabled;

  /// Seeds Firestore with default plans.
  ///
  /// **Do not call from production app code.** Use admin tools or migrations.
  @Deprecated('Catalog writes must not run from end-user clients')
  Future<void> addDefaultSubscriptionPlans() async {
    if (!firestoreCatalogEnabled) {
      logger.d(
        'addDefaultSubscriptionPlans skipped (subscription Firestore off).',
      );
      return;
    }
    try {
      final List<SubscriptionPlan> plans = _getDefaultSubscriptionPlans();

      // Add each plan to Firestore
      for (final plan in plans) {
        await _firestore
            .collection('subscription_plans')
            .doc(plan.id)
            .set(plan.toJson());
      }

      logger.d(
        '✅ Successfully added ${plans.length} subscription plans to Firestore',
      );
    } catch (e) {
      logger.d('❌ Error adding subscription plans: $e');
      rethrow;
    }
  }

  /// Get all subscription plans from Firestore
  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    if (!firestoreCatalogEnabled) {
      logger.d(
        'Subscription plans: using defaults (subscription Firestore off).',
      );
      return _getDefaultSubscriptionPlans();
    }
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('subscription_plans')
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => SubscriptionPlan.fromJson(doc.data()))
          .toList();
    } catch (e) {
      logger.d('❌ Error fetching subscription plans: $e');
      return _getDefaultSubscriptionPlans(); // Fallback to default plans
    }
  }

  /// Create a user's premium status document
  Future<void> createUserPremiumStatus(String userId) async {
    if (!firestoreCatalogEnabled) {
      logger.d(
        'createUserPremiumStatus skipped for $userId (subscription Firestore off).',
      );
      return;
    }
    try {
      final Map<String, Object?> premiumStatus = {
        'isPremium': false,
        'subscriptionStartDate': null,
        'subscriptionEndDate': null,
        'subscriptionType': null,
        'isTrialUsed': false,
        'trialStartDate': null,
        'trialEndDate': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('premium')
          .doc('status')
          .set(premiumStatus);

      logger.d('✅ Created premium status for user: $userId');
    } catch (e) {
      logger.d('❌ Error creating user premium status: $e');
      rethrow;
    }
  }

  /// Create a purchase record
  Future<void> createPurchaseRecord({
    required String userId,
    required String planId,
    required String planName,
    required double price,
    required String currency,
    required String transactionId,
  }) async {
    if (!firestoreCatalogEnabled) {
      logger.d(
        'createPurchaseRecord skipped for $userId (subscription Firestore off).',
      );
      return;
    }
    try {
      final Map<String, Object> purchaseRecord = {
        'planId': planId,
        'planName': planName,
        'price': price,
        'currency': currency,
        'transactionId': transactionId,
        'purchaseDate': FieldValue.serverTimestamp(),
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('purchases')
          .add(purchaseRecord);

      logger.d('✅ Created purchase record for user: $userId');
    } catch (e) {
      logger.d('❌ Error creating purchase record: $e');
      rethrow;
    }
  }

  /// Get default subscription plans
  List<SubscriptionPlan> _getDefaultSubscriptionPlans() {
    return [
      const SubscriptionPlan(
        id: 'monthly_basic',
        name: 'Monthly Basic',
        description: 'Access to all premium features for one month',
        price: 150.0,
        currency: CurrencyConfig.currencyCode,
        type: SubscriptionType.monthly,
        durationInDays: 30,
        features: [
          'Unlimited downloads',
          'High quality audio',
          'Offline listening',
          'No ads',
          'Priority support',
        ],
        isPopular: false,
        discountPercentage: null,
        order: 1,
      ),
      const SubscriptionPlan(
        id: 'monthly_premium',
        name: 'Monthly Premium',
        description: 'Best value monthly plan with all features',
        price: 240.0,
        currency: CurrencyConfig.currencyCode,
        type: SubscriptionType.monthly,
        durationInDays: 30,
        features: [
          'Everything in Basic',
          'Exclusive reciters',
          'Advanced audio controls',
          'Cloud sync',
          'Early access to new features',
        ],
        isPopular: true,
        discountPercentage: null,
        order: 2,
      ),
      const SubscriptionPlan(
        id: 'yearly_basic',
        name: 'Yearly Basic',
        description: 'Save 20% with yearly subscription',
        price: 1440.0,
        currency: CurrencyConfig.currencyCode,
        type: SubscriptionType.yearly,
        durationInDays: 365,
        features: [
          'Everything in Monthly Basic',
          'Save 20% compared to monthly',
          'Priority customer support',
        ],
        isPopular: false,
        discountPercentage: 20.0,
        order: 3,
      ),
      const SubscriptionPlan(
        id: 'yearly_premium',
        name: 'Yearly Premium',
        description: 'Best value - Save 30% with yearly premium',
        price: 2040.0,
        currency: CurrencyConfig.currencyCode,
        type: SubscriptionType.yearly,
        durationInDays: 365,
        features: [
          'Everything in Monthly Premium',
          'Save 30% compared to monthly',
          'Exclusive yearly bonuses',
          'Priority feature requests',
        ],
        isPopular: true,
        discountPercentage: 30.0,
        order: 4,
      ),
      const SubscriptionPlan(
        id: 'lifetime',
        name: 'Lifetime Access',
        description: 'One-time payment for lifetime access',
        price: 3000.0,
        currency: CurrencyConfig.currencyCode,
        type: SubscriptionType.lifetime,
        durationInDays: 36500,
        features: [
          'Everything in Premium',
          'Lifetime access',
          'No recurring payments',
          'Future updates included',
          'VIP support',
        ],
        isPopular: false,
        discountPercentage: 50.0,
        order: 5,
      ),
    ];
  }
}
