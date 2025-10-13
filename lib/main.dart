import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:muzakri/app_bloc_observer.dart';
import 'package:muzakri/core/di/injection.dart';
import 'package:muzakri/core/services/analytics_initialization_service.dart';
import 'package:muzakri/core/services/crashlytics_service.dart';
import 'package:muzakri/core/services/firebase_initialization_service.dart';
import 'package:muzakri/firebase_options.dart';
import 'package:muzakri/quran_player_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first, then DI
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await configureDependencies();

  // Initialize Crashlytics first (handles error reporting)
  await _initializeCrashlytics();

  // Initialize Google Sign-In with server client ID
  await _initializeGoogleSignIn();

  // Initialize Analytics
  await _initializeAnalytics();

  // Initialize Firebase data asynchronously after app starts
  _initializeFirebaseDataAsync();

  Bloc.observer = AppBlocObserver();

  runApp(const QuranPlayerApp());
}

/// Initialize Google Sign-In with server client ID
Future<void> _initializeGoogleSignIn() async {
  try {
    final googleSignIn = getIt<GoogleSignIn>();
    await googleSignIn.initialize(
      serverClientId:
          '181575856185-2ioqgr7miir7hj7hvgcsi7qp7juo2gco.apps.googleusercontent.com',
    );
  } catch (e) {
    print('Warning: Could not initialize Google Sign-In: $e');
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
