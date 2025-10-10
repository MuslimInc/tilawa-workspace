import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:muzakri/core/di/injection.dart';
import 'package:muzakri/core/services/firebase_initialization_service.dart';
import 'package:muzakri/firebase_options.dart';
import 'package:muzakri/quran_player_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first, then DI
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await configureDependencies();

  // Initialize Google Sign-In with server client ID
  await _initializeGoogleSignIn();

  // Initialize Firebase data asynchronously after app starts
  _initializeFirebaseDataAsync();

  // Bloc.observer = AppBlocObserver();

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
