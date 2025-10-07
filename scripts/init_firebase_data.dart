#!/usr/bin/env dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:muzakri/core/services/firebase_initialization_service.dart';
import 'package:muzakri/features/premium/data/services/subscription_plans_service.dart';

/// Script to initialize Firebase with subscription plans
/// Run with: dart scripts/init_firebase_data.dart
Future<void> main() async {
  print('🔥 Initializing Firebase Data');
  print('============================');

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
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
    print('You can now view your data in the Firebase Console at:');
    print('https://console.firebase.google.com/');
  } catch (e) {
    print('❌ Error initializing Firebase data: $e');
    exit(1);
  }
}
