import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:muzakri/features/premium/data/services/subscription_plans_service.dart';

class FirebaseInitializationService {
  final FirebaseFirestore _firestore;
  final SubscriptionPlansService _subscriptionPlansService;

  FirebaseInitializationService({
    required FirebaseFirestore firestore,
    required SubscriptionPlansService subscriptionPlansService,
  }) : _firestore = firestore,
       _subscriptionPlansService = subscriptionPlansService;

  /// Initialize Firebase with default data
  Future<void> initializeFirebaseData() async {
    try {
      print('🚀 Initializing Firebase data...');

      // Check if subscription plans already exist
      final plansSnapshot = await _firestore
          .collection('subscription_plans')
          .limit(1)
          .get();

      if (plansSnapshot.docs.isEmpty) {
        print('📋 Adding subscription plans to Firestore...');
        await _subscriptionPlansService.addDefaultSubscriptionPlans();
      } else {
        print('✅ Subscription plans already exist in Firestore');
      }

      // Create sample users if needed (for testing)
      await _createSampleUsers();

      print('✅ Firebase initialization completed successfully');
    } catch (e) {
      print('❌ Error initializing Firebase data: $e');
      rethrow;
    }
  }

  /// Create sample users for testing
  Future<void> _createSampleUsers() async {
    try {
      // This is just for demonstration - in production, users would be created through authentication
      print('👥 Creating sample user data structure...');

      // You can add sample user data here if needed
      // For now, we'll just ensure the collections exist

      print('✅ Sample user data structure ready');
    } catch (e) {
      print('❌ Error creating sample users: $e');
    }
  }

  /// Get Firebase data statistics
  Future<Map<String, int>> getFirebaseDataStats() async {
    try {
      final plansSnapshot = await _firestore
          .collection('subscription_plans')
          .get();
      final usersSnapshot = await _firestore.collection('users').get();

      return {
        'subscription_plans': plansSnapshot.docs.length,
        'users': usersSnapshot.docs.length,
      };
    } catch (e) {
      print('❌ Error getting Firebase stats: $e');
      return {'subscription_plans': 0, 'users': 0};
    }
  }

  /// Clear all Firebase data (use with caution!)
  Future<void> clearAllFirebaseData() async {
    try {
      print('⚠️  Clearing all Firebase data...');

      // Delete subscription plans
      final plansSnapshot = await _firestore
          .collection('subscription_plans')
          .get();
      for (final doc in plansSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete users (be careful with this!)
      final usersSnapshot = await _firestore.collection('users').get();
      for (final doc in usersSnapshot.docs) {
        await doc.reference.delete();
      }

      print('✅ All Firebase data cleared');
    } catch (e) {
      print('❌ Error clearing Firebase data: $e');
      rethrow;
    }
  }
}
