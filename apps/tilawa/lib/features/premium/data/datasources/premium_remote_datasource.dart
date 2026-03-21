import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/config/currency_config.dart';
import '../../../../main.dart';
import '../../domain/entities/premium_status.dart';
import '../../domain/entities/subscription_plan.dart';

abstract class PremiumRemoteDataSource {
  Future<PremiumStatus?> getPremiumStatus();
  Future<void> updatePremiumStatus(PremiumStatus status);
  Future<List<SubscriptionPlan>> getAvailablePlans();
  Future<bool> purchaseSubscription(String planId);
  Future<bool> cancelSubscription();
  Future<bool> restoreSubscription();
}

@LazySingleton(as: PremiumRemoteDataSource)
class PremiumRemoteDataSourceImpl implements PremiumRemoteDataSource {
  PremiumRemoteDataSourceImpl(this._firestore, this._auth);
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<PremiumStatus?> getPremiumStatus() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      final DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('premium')
          .doc('status')
          .get();

      if (doc.exists && doc.data() != null) {
        return PremiumStatus.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      logger.d('Error fetching premium status from Firebase: $e');
      return null;
    }
  }

  @override
  Future<void> updatePremiumStatus(PremiumStatus status) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('premium')
          .doc('status')
          .set(status.toJson());
    } catch (e) {
      logger.d('Error updating premium status on Firebase: $e');
      rethrow;
    }
  }

  @override
  Future<List<SubscriptionPlan>> getAvailablePlans() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection('subscription_plans')
          .orderBy('order', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => SubscriptionPlan.fromJson(doc.data()))
          .toList();
    } catch (e) {
      logger.d('Error fetching plans from Firebase: $e');
      // Return default plans if Firebase fails
      return _getDefaultPlans();
    }
  }

  @override
  Future<bool> purchaseSubscription(String planId) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      // Create purchase record in Firebase
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('purchases')
          .add({
            'planId': planId,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'completed',
          });

      // Update premium status
      final now = DateTime.now();
      final status = PremiumStatus(
        isPremium: true,
        subscriptionStartDate: now,
        subscriptionEndDate: _calculateEndDate(planId, now),
        subscriptionType: planId,
        isTrialUsed: false,
        trialStartDate: null,
        trialEndDate: null,
      );

      await updatePremiumStatus(status);
      return true;
    } catch (e) {
      logger.d('Error purchasing subscription: $e');
      return false;
    }
  }

  @override
  Future<bool> cancelSubscription() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      // Create cancellation record
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cancellations')
          .add({
            'timestamp': FieldValue.serverTimestamp(),
            'reason': 'user_requested',
          });

      // Update premium status to cancelled
      final PremiumStatus? currentStatus = await getPremiumStatus();
      if (currentStatus != null) {
        final PremiumStatus updatedStatus = currentStatus.copyWith(
          isPremium: false,
          subscriptionEndDate: DateTime.now(),
        );
        await updatePremiumStatus(updatedStatus);
      }

      return true;
    } catch (e) {
      logger.d('Error canceling subscription: $e');
      return false;
    }
  }

  @override
  Future<bool> restoreSubscription() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      // Check for recent purchases
      final QuerySnapshot<Map<String, dynamic>> purchasesQuery =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('purchases')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

      if (purchasesQuery.docs.isNotEmpty) {
        final Map<String, dynamic> purchase = purchasesQuery.docs.first.data();
        final planId = purchase['planId'] as String;

        // Restore the subscription
        final now = DateTime.now();
        final status = PremiumStatus(
          isPremium: true,
          subscriptionStartDate: now,
          subscriptionEndDate: _calculateEndDate(planId, now),
          subscriptionType: planId,
          isTrialUsed: false,
          trialStartDate: null,
          trialEndDate: null,
        );

        await updatePremiumStatus(status);
        return true;
      }

      return false;
    } catch (e) {
      logger.d('Error restoring subscription: $e');
      return false;
    }
  }

  // Helper method to calculate subscription end date
  DateTime _calculateEndDate(String planId, DateTime startDate) {
    switch (planId) {
      case 'monthly':
        return startDate.add(const Duration(days: 30));
      case 'yearly':
        return startDate.add(const Duration(days: 365));
      case 'lifetime':
        return startDate.add(const Duration(days: 36500)); // ~100 years
      default:
        return startDate.add(const Duration(days: 30));
    }
  }

  // Default plans fallback
  List<SubscriptionPlan> _getDefaultPlans() {
    return [
      const SubscriptionPlan(
        id: 'monthly',
        name: 'Monthly Premium',
        description: 'Full access to all premium features',
        price: 4.99,
        currency: CurrencyConfig.currencyCode,
        type: SubscriptionType.monthly,
        durationInDays: 30,
        features: [
          'Unlimited Downloads',
          'Offline Mode',
          'High Quality Audio',
          'Ad-Free Experience',
        ],
        isPopular: false,
        discountPercentage: null,
      ),
      const SubscriptionPlan(
        id: 'yearly',
        name: 'Yearly Premium',
        description: 'Best value - Save 50%',
        price: 29.99,
        currency: CurrencyConfig.currencyCode,
        type: SubscriptionType.yearly,
        durationInDays: 365,
        features: [
          'Unlimited Downloads',
          'Offline Mode',
          'High Quality Audio',
          'Ad-Free Experience',
          'Priority Support',
        ],
        isPopular: true,
        discountPercentage: 50.0,
      ),
      const SubscriptionPlan(
        id: 'lifetime',
        name: 'Lifetime Premium',
        description: 'One-time payment, lifetime access',
        price: 99.99,
        currency: CurrencyConfig.currencyCode,
        type: SubscriptionType.lifetime,
        durationInDays: 36500,
        features: [
          'Unlimited Downloads',
          'Offline Mode',
          'High Quality Audio',
          'Ad-Free Experience',
          'Priority Support',
          'Exclusive Content',
        ],
        isPopular: false,
        discountPercentage: 80.0,
      ),
    ];
  }
}
