import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../features/premium/data/services/subscription_catalog_prefetch_impl.dart';
import '../../features/premium/data/services/subscription_plans_service.dart';
import '../../firebase_options.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import '../services/firebase_initialization_service.dart';

/// Command-line tool to verify Firebase data (read-only).
///
/// Catalog seeding should be done via an admin backend or migration script,
/// NOT from the client app.
///
/// Run this with: dart lib/core/utils/firebase_data_initializer.dart
Future<void> main() async {
  logger.d('Firebase Data Initializer (read-only)');
  logger.d('============================');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.d('Firebase initialized');

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final subscriptionPlansService = SubscriptionPlansService(
      firestore: firestore,
      firestoreCatalogEnabled: true,
    );
    final initializationService = FirebaseInitializationService(
      SubscriptionCatalogPrefetchImpl(subscriptionPlansService),
    );

    // Pre-fetch subscription plans (read-only)
    await initializationService.initializeFirebaseData();

    logger.d('Firebase data read completed successfully.');
  } catch (e) {
    logger.d('Error initializing Firebase data: $e');
    exit(1);
  }
}
