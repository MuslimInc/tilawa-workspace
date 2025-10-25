import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:muzakri/core/config/firebase_options.dart';
import 'package:muzakri/core/services/firebase_initialization_service.dart';
import 'package:muzakri/features/premium/data/services/subscription_plans_service.dart';

/// Command-line tool to initialize Firebase data
/// Run this with: dart lib/core/utils/firebase_data_initializer.dart
Future<void> main() async {
  print('🔥 Firebase Data Initializer');
  print('============================');

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');

    // Create services
    final firestore = FirebaseFirestore.instance;
    final subscriptionPlansService = SubscriptionPlansService(
      firestore: firestore,
    );
    final initializationService = FirebaseInitializationService(
      firestore: firestore,
      subscriptionPlansService: subscriptionPlansService,
    );

    // Initialize data
    await initializationService.initializeFirebaseData();

    // Show statistics
    final stats = await initializationService.getFirebaseDataStats();
    print('\n📊 Firebase Data Statistics:');
    print('Subscription Plans: ${stats['subscription_plans']}');
    print('Users: ${stats['users']}');

    print('\n✅ Firebase data initialization completed successfully!');
    print('You can now view your data in the Firebase Console.');
  } catch (e) {
    print('❌ Error initializing Firebase data: $e');
    exit(1);
  }
}
