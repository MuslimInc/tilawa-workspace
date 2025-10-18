import 'dart:async';

import 'package:credential_manager/credential_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:muzakri/core/di/injection.dart';
import 'package:muzakri/core/services/analytics_initialization_service.dart';
import 'package:muzakri/core/services/crashlytics_service.dart';
import 'package:muzakri/core/services/firebase_initialization_service.dart';
import 'package:muzakri/firebase_options.dart';
import 'package:muzakri/quran_player_app.dart';

final logger = Logger();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first, then DI
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await configureDependencies();

  // Initialize Crashlytics first (handles error reporting)
  await _initializeCrashlytics();

  // Initialize Credential Manager
  await _initializeCredentialManager();

  // Initialize Analytics
  await _initializeAnalytics();

  // Initialize Firebase data asynchronously after app starts
  _initializeFirebaseDataAsync();

  // Bloc.observer = AppBlocObserver();

  runApp(const QuranPlayerApp());
}

/// Initialize Credential Manager with Google Client ID
Future<void> _initializeCredentialManager() async {
  try {
    final credentialManager = getIt<CredentialManager>();
    await credentialManager.init(
      preferImmediatelyAvailableCredentials: true,
      googleClientId:
          '181575856185-2ioqgr7miir7hj7hvgcsi7qp7juo2gco.apps.googleusercontent.com',
    );
    print('Credential Manager initialized successfully');
  } catch (e) {
    print('Warning: Could not initialize Credential Manager: $e');
  }
}

/// Initialize Crashlytics
Future<void> _initializeCrashlytics() async {
  try {
    final crashlyticsService = getIt<CrashlyticsService>();
    await crashlyticsService.initialize();
    print('Crashlytics initialized successfully');
  } catch (e) {
    print('Crashlytics initialization error: $e');
  }
}

/// Initialize Analytics
Future<void> _initializeAnalytics() async {
  try {
    final analyticsInitService = getIt<AnalyticsInitializationService>();
    await analyticsInitService.initialize();
    print('Analytics initialized successfully');
  } catch (e) {
    print('Analytics initialization error: $e');
  }
}

/// Initialize Firebase data asynchronously to avoid blocking main thread
void _initializeFirebaseDataAsync() {
  Future.microtask(() async {
    try {
      final firebaseInitService = getIt<FirebaseInitializationService>();
      await firebaseInitService.initializeFirebaseData();
    } catch (e) {
      print('Warning: Could not initialize Firebase data: $e');
    }
  });
}
