import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:muzakri/features/premium/data/services/subscription_plans_service.dart';

/// Simple test to verify Firebase connection and add subscription plans
/// Run this with: dart lib/core/utils/test_firebase_connection.dart
Future<void> main() async {
  print('🔥 Testing Firebase Connection');
  print('==============================');

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialized');

    // Test Firestore connection
    final firestore = FirebaseFirestore.instance;

    print('📡 Testing Firestore connection...');

    // Create a test document
    await firestore.collection('test').doc('connection').set({
      'message': 'Hello from Muzakri!',
      'timestamp': FieldValue.serverTimestamp(),
    });
    print('✅ Firestore write successful');

    // Read the test document
    final doc = await firestore.collection('test').doc('connection').get();
    if (doc.exists) {
      print('✅ Firestore read successful: ${doc.data()}');
    }

    // Clean up test document
    await firestore.collection('test').doc('connection').delete();
    print('✅ Test document cleaned up');

    // Test subscription plans service
    print('\n📋 Testing Subscription Plans Service...');
    final subscriptionPlansService = SubscriptionPlansService(
      firestore: firestore,
    );

    // Add subscription plans
    await subscriptionPlansService.addDefaultSubscriptionPlans();
    print('✅ Subscription plans added successfully');

    // Get subscription plans
    final plans = await subscriptionPlansService.getSubscriptionPlans();
    print('✅ Retrieved ${plans.length} subscription plans');

    // Print plan details
    for (final plan in plans) {
      print('  - ${plan.name}: \$${plan.price} (${plan.type.name})');
    }

    print('\n🎉 Firebase setup completed successfully!');
    print('You can now view your data in the Firebase Console at:');
    print('https://console.firebase.google.com/');
  } catch (e) {
    print('❌ Error testing Firebase: $e');
    print('\nTroubleshooting:');
    print('1. Make sure your Firebase project is properly configured');
    print(
      '2. Check that google-services.json (Android) and GoogleService-Info.plist (iOS) are in place',
    );
    print('3. Verify your Firebase project has Firestore enabled');
    print('4. Check your internet connection');
  }
}
