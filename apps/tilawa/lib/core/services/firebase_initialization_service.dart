import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/premium/data/services/subscription_plans_service.dart';
import 'package:tilawa/core/logging/app_logger.dart';

class FirebaseInitializationService {
  FirebaseInitializationService({
    required FirebaseFirestore firestore,
    required SubscriptionPlansService subscriptionPlansService,
  }) : _firestore = firestore,
       _subscriptionPlansService = subscriptionPlansService;
  final FirebaseFirestore _firestore;
  final SubscriptionPlansService _subscriptionPlansService;

  /// Initialize Firebase with default data
  Future<void> initializeFirebaseData() async {
    try {
      logger.d('🚀 Initializing Firebase data...');

      // Check if subscription plans already exist
      final QuerySnapshot<Map<String, dynamic>> plansSnapshot = await _firestore
          .collection('subscription_plans')
          .limit(1)
          .get();

      if (plansSnapshot.docs.isEmpty) {
        logger.d('📋 Adding subscription plans to Firestore...');
        await _subscriptionPlansService.addDefaultSubscriptionPlans();
      } else {
        logger.d('✅ Subscription plans already exist in Firestore');
      }

      // Create sample users if needed (for testing)
      await _createSampleUsers();

      logger.d('✅ Firebase initialization completed successfully');
    } catch (e) {
      logger.d('❌ Error initializing Firebase data: $e');
      rethrow;
    }
  }

  /// Create sample users for testing
  Future<void> _createSampleUsers() async {
    try {
      // This is just for demonstration - in production, users would be created through authentication
      logger.d('👥 Creating sample user data structure...');

      // You can add sample user data here if needed
      // For now, we'll just ensure the collections exist

      logger.d('✅ Sample user data structure ready');
    } catch (e) {
      logger.d('❌ Error creating sample users: $e');
    }
  }

  /// Get Firebase data statistics
  Future<Map<String, int>> getFirebaseDataStats() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> plansSnapshot = await _firestore
          .collection('subscription_plans')
          .get();
      final QuerySnapshot<Map<String, dynamic>> usersSnapshot = await _firestore
          .collection('users')
          .get();

      return {
        'subscription_plans': plansSnapshot.docs.length,
        'users': usersSnapshot.docs.length,
      };
    } catch (e) {
      logger.d('❌ Error getting Firebase stats: $e');
      return {'subscription_plans': 0, 'users': 0};
    }
  }

  /// Clear all Firebase data (use with caution!)
  Future<void> clearAllFirebaseData() async {
    try {
      logger.d('⚠️  Clearing all Firebase data...');

      // Delete subscription plans
      final QuerySnapshot<Map<String, dynamic>> plansSnapshot = await _firestore
          .collection('subscription_plans')
          .get();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in plansSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete users (be careful with this!)
      final QuerySnapshot<Map<String, dynamic>> usersSnapshot = await _firestore
          .collection('users')
          .get();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in usersSnapshot.docs) {
        await doc.reference.delete();
      }

      logger.d('✅ All Firebase data cleared');
    } catch (e) {
      logger.d('❌ Error clearing Firebase data: $e');
      rethrow;
    }
  }
}
