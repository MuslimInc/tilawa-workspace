import 'package:audio_service/audio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:credential_manager/credential_manager.dart';
import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/downloads/data/services/download_service.dart';
import '../../features/premium/data/services/subscription_plans_service.dart';
import '../../main.dart';
import '../../shared/audio/audio_player_handler.dart';
import '../../shared/audio/audio_player_handler_impl.dart';
import '../config/api_config.dart';
import '../services/analytics_service.dart';
import '../services/firebase_initialization_service.dart';

@module
abstract class ExternalDependenciesModule {
  @singleton
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  @singleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  @singleton
  GoogleSignIn get googleSignIn => GoogleSignIn.instance;

  @singleton
  CredentialManager get credentialManager => CredentialManager();

  @singleton
  FirebaseAnalytics get firebaseAnalytics => FirebaseAnalytics.instance;

  @singleton
  FirebaseCrashlytics get firebaseCrashlytics => FirebaseCrashlytics.instance;

  @singleton
  SharedPreferencesAsync get sharedPreferences => SharedPreferencesAsync();

  @singleton
  Dio dioClient() => Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      followRedirects: true,
      maxRedirects: 5,
      validateStatus: (status) => status != null && status < 500,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'muzakri/1.0 (Flutter; Dart)',
      },
    ),
  );

  @singleton
  SubscriptionPlansService subscriptionPlansService(
    FirebaseFirestore firestore,
  ) => SubscriptionPlansService(firestore: firestore);

  @singleton
  FirebaseInitializationService firebaseInitializationService(
    FirebaseFirestore firestore,
    SubscriptionPlansService subscriptionPlansService,
  ) => FirebaseInitializationService(
    firestore: firestore,
    subscriptionPlansService: subscriptionPlansService,
  );

  @singleton
  List<MediaItem> mediaItemList() => [];

  @preResolve
  @singleton
  Future<AudioPlayerHandler> audioPlayerHandler(
    List<MediaItem> mediaItems,
    AnalyticsService analyticsService,
    SharedPreferencesAsync prefs,
  ) async {
    try {
      logger.d('Initializing audio service...');
      final audioPlayerHandlerImpl = AudioPlayerHandlerImpl(
        mediaItems,
        analyticsService,
        prefs,
      );

      final AudioPlayerHandlerImpl audioHandler = await AudioService.init(
        builder: () => audioPlayerHandlerImpl,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.ryanheise.myapp.channel.audio',
          androidNotificationChannelName: 'Audio playback',
          androidNotificationOngoing: true,
        ),
      );
      logger.d('Audio service initialized successfully');
      return audioHandler;
    } catch (e) {
      logger.d('Warning: Could not initialize audio service: $e');
      // Register a fallback handler to prevent crashes
      final fallbackHandler = AudioPlayerHandlerImpl(
        [],
        analyticsService,
        prefs,
      );
      logger.d('Fallback AudioPlayerHandler registered');
      return fallbackHandler;
    }
  }

  @singleton
  DownloadService get downloadService => DownloadServiceImpl.instance;
}
