import 'package:cloud_firestore/cloud_firestore.dart';
// No FirebaseAuth dependency required here
import 'package:muzakri/features/premium/domain/entities/subscription_plan.dart';

class SubscriptionPlansService {
  final FirebaseFirestore _firestore;

  SubscriptionPlansService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  /// Add default subscription plans to Firestore
  Future<void> addDefaultSubscriptionPlans() async {
    try {
      final plans = _getDefaultSubscriptionPlans();

      // Add each plan to Firestore
      for (final plan in plans) {
        await _firestore
            .collection('subscription_plans')
            .doc(plan.id)
            .set(plan.toJson());
      }

      print(
        '✅ Successfully added ${plans.length} subscription plans to Firestore',
      );
    } catch (e) {
      print('❌ Error adding subscription plans: $e');
      rethrow;
    }
  }

  /// Get all subscription plans from Firestore
  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      final snapshot = await _firestore
          .collection('subscription_plans')
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => SubscriptionPlan.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error fetching subscription plans: $e');
      return _getDefaultSubscriptionPlans(); // Fallback to default plans
    }
  }

  /// Create a user's premium status document
  Future<void> createUserPremiumStatus(String userId) async {
    try {
      final premiumStatus = {
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

      print('✅ Created premium status for user: $userId');
    } catch (e) {
      print('❌ Error creating user premium status: $e');
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
    try {
      final purchaseRecord = {
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

      print('✅ Created purchase record for user: $userId');
    } catch (e) {
      print('❌ Error creating purchase record: $e');
      rethrow;
    }
  }

  /// Get default subscription plans
  List<SubscriptionPlan> _getDefaultSubscriptionPlans() {
    return [
      SubscriptionPlan(
        id: 'monthly_basic',
        name: 'Monthly Basic',
        description: 'Access to all premium features for one month',
        price: 4.99,
        currency: 'USD',
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
      SubscriptionPlan(
        id: 'monthly_premium',
        name: 'Monthly Premium',
        description: 'Best value monthly plan with all features',
        price: 7.99,
        currency: 'USD',
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
      SubscriptionPlan(
        id: 'yearly_basic',
        name: 'Yearly Basic',
        description: 'Save 20% with yearly subscription',
        price: 47.99,
        currency: 'USD',
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
      SubscriptionPlan(
        id: 'yearly_premium',
        name: 'Yearly Premium',
        description: 'Best value - Save 30% with yearly premium',
        price: 67.99,
        currency: 'USD',
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
      SubscriptionPlan(
        id: 'lifetime',
        name: 'Lifetime Access',
        description: 'One-time payment for lifetime access',
        price: 99.99,
        currency: 'USD',
        type: SubscriptionType.lifetime,
        durationInDays: 36500, // ~100 years
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
