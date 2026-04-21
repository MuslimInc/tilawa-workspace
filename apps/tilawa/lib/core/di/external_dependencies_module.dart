import 'package:audio_service/audio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:credential_manager/credential_manager.dart';
import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:tilawa/features/premium/data/services/subscription_plans_service.dart';
import 'package:tilawa/features/reciters/domain/repositories/reciters_repository.dart';
import 'package:tilawa_core/config/api_config.dart';
import 'package:tilawa_core/services/analytics_service.dart';

import '../../shared/audio/audio_player_handler.dart';
import '../../shared/audio/audio_player_handler_impl.dart';
import '../services/firebase_initialization_service.dart';

@module
abstract class ExternalDependenciesModule {
  @singleton
  Logger get loggerInstance => logger;

  @lazySingleton
  Connectivity get connectivity => Connectivity();

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
  FirebaseMessaging get firebaseMessaging => FirebaseMessaging.instance;

  @singleton
  SharedPreferencesAsync get sharedPreferences => SharedPreferencesAsync();

  @singleton
  HiveInterface get hive => Hive;

  @singleton
  Dio dioClient() => Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      followRedirects: true,
      maxRedirects: 5,
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'tilawa/1.0 (Flutter; Dart)',
      },
    ),
  );

  @singleton
  SubscriptionPlansService subscriptionPlansService(
    FirebaseFirestore firestore,
  ) => SubscriptionPlansService(firestore: firestore);

  @singleton
  FirebaseInitializationService firebaseInitializationService(
    SubscriptionPlansService subscriptionPlansService,
  ) => FirebaseInitializationService(
    subscriptionPlansService: subscriptionPlansService,
  );

  @singleton
  List<MediaItem> mediaItemList() => [];

  @singleton
  AudioPlayerHandler audioPlayerHandler(
    List<MediaItem> mediaItems,
    AnalyticsService analyticsService,
    SharedPreferencesAsync prefs,
    RecitersRepository recitersRepository,
    DownloadsRepository downloadsRepository,
  ) {
    // Create the handler synchronously so DI doesn't block the first frame.
    // AudioService.init() (the platform notification bridge) is deferred to
    // initializeAudioService() which runs post-frame in main.dart.
    return AudioPlayerHandlerImpl(
      mediaItems,
      analyticsService,
      prefs,
      recitersRepository,
      downloadsRepository,
    );
  }

  @singleton
  AssetBundle get assetBundle => rootBundle;

  @singleton
  QuranFontService get quranFontService => QuranFontService();
}
