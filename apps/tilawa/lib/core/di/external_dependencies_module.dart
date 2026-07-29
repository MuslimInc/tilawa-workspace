import 'package:audio_service/audio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_ce/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logger/logger.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/bootstrap/shared_preferences_migration.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/features/audio_player/domain/services/artist_media_playlist_cache.dart';
import 'package:tilawa/features/audio_player/domain/services/audio_entity_media_item_mapper.dart';
import 'package:tilawa/features/audio_player/domain/services/moshaf_surah_audio_list_builder.dart';
import 'package:tilawa/features/audio_player/domain/services/playback_uri_resolver.dart';
import 'package:tilawa/features/audio_player/domain/services/reciter_audio_catalog_cache.dart';
import 'package:tilawa/features/premium/data/services/subscription_plans_service.dart';
import 'package:tilawa_core/config/api_config.dart';
import 'package:tilawa_core/services/analytics_service.dart';

import '../../shared/audio/audio_player_handler.dart';
import '../../shared/audio/audio_player_handler_impl.dart';

/// Third-party / platform SDK wiring for GetIt.
class ExternalDependenciesModule {
  ExternalDependenciesModule._();

  static void register(GetIt getIt) {
    getIt.registerEagerSingletonIfAbsent<Logger>(() => logger);
    getIt.registerLazySingletonIfAbsent<Connectivity>(Connectivity.new);
    getIt.registerLazySingletonIfAbsent<DeviceInfoPlugin>(DeviceInfoPlugin.new);
    getIt.registerEagerSingletonIfAbsent<FirebaseFirestore>(
      () => FirebaseFirestore.instance,
    );
    getIt.registerEagerSingletonIfAbsent<FirebaseFunctions>(
      () => FirebaseFunctions.instanceFor(region: 'us-central1'),
    );
    getIt.registerEagerSingletonIfAbsent<InAppPurchase>(
      () => InAppPurchase.instance,
    );
    getIt.registerEagerSingletonIfAbsent<FirebaseAuth>(
      () => FirebaseAuth.instance,
    );
    getIt.registerEagerSingletonIfAbsent<FirebaseStorage>(
      () => FirebaseStorage.instance,
    );
    getIt.registerEagerSingletonIfAbsent<GoogleSignIn>(
      () => GoogleSignIn.instance,
    );
    getIt.registerEagerSingletonIfAbsent<FirebaseAnalytics>(
      () => FirebaseAnalytics.instance,
    );
    getIt.registerEagerSingletonIfAbsent<FirebaseCrashlytics>(
      () => FirebaseCrashlytics.instance,
    );
    getIt.registerEagerSingletonIfAbsent<FirebaseMessaging>(
      () => FirebaseMessaging.instance,
    );
    getIt.registerEagerSingletonIfAbsent<FirebasePerformance>(
      () => FirebasePerformance.instance,
    );
    getIt.registerEagerSingletonIfAbsent<SharedPreferencesAsync>(
      () => SharedPreferencesAsync(options: tilawaSharedPreferencesOptions),
    );
    getIt.registerEagerSingletonIfAbsent<HiveInterface>(() => Hive);
    getIt.registerEagerSingletonIfAbsent<Dio>(
      () => Dio(
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
      ),
    );
    getIt.registerEagerSingletonIfAbsent<List<MediaItem>>(() => <MediaItem>[]);
    getIt.registerEagerSingletonIfAbsent<AssetBundle>(() => rootBundle);
    getIt.registerEagerSingletonIfAbsent<QuranFontService>(
      () => QuranFontService(
        mushafService: quranQcfLocator<MushafService>(),
        idleScheduler: quranQcfLocator<IdleScheduler>(),
      ),
    );

    // Lazy: depends on types registered by feature modules.
    getIt.registerLazySingletonIfAbsent<SubscriptionPlansService>(
      () => SubscriptionPlansService(
        firestore: getIt<FirebaseFirestore>(),
        firestoreCatalogEnabled:
            getIt<AppLaunchConfig>().subscriptionServiceEnabled,
      ),
    );
    // Lazy so DI does not block the first frame; AudioService.init stays deferred.
    getIt.registerLazySingletonIfAbsent<AudioPlayerHandler>(
      () => AudioPlayerHandlerImpl(
        getIt<List<MediaItem>>(),
        getIt<AnalyticsService>(),
        getIt<ReciterAudioCatalogCache>(),
        getIt<PlaybackUriResolver>(),
        getIt<MoshafSurahAudioListBuilder>(),
        getIt<ArtistMediaPlaylistCache>(),
        getIt<AudioEntityMediaItemMapper>(),
      ),
    );
  }
}
