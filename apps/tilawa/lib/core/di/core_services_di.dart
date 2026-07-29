import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/bootstrap/app_startup_readiness.dart';
import 'package:tilawa/core/bootstrap/startup_launch_coordinator.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/core/domain/server_action_guard.dart';
import 'package:tilawa/core/presentation/cubit/ui_visibility_cubit.dart';
import 'package:tilawa/core/services/analytics_initialization_service.dart';
import 'package:tilawa/core/services/android_adhan_alarm_player.dart';
import 'package:tilawa/core/services/crashlytics_service.dart';
import 'package:tilawa/core/services/device_token_service.dart';
import 'package:tilawa/core/services/firebase_initialization_service.dart';
import 'package:tilawa/core/services/hive_readiness.dart';
import 'package:tilawa/core/services/hive_readiness_gate.dart';
import 'package:tilawa/core/services/navigation_service.dart';
import 'package:tilawa/core/services/notification_permission_service.dart';
import 'package:tilawa/core/services/notification_startup_service.dart';
import 'package:tilawa/core/services/quran_assets_prefetch_policy_service.dart';
import 'package:tilawa/core/wrappers/location_service_wrapper.dart';
import 'package:tilawa/core/wrappers/qibla_service_wrapper.dart';
import 'package:tilawa/features/auth/domain/usecases/prepare_google_sign_in_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import 'package:tilawa/features/premium/domain/services/subscription_catalog_prefetch.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_favorite_reciters_use_case.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';
import 'package:tilawa/features/splash/domain/usecases/get_splash_next_route_use_case.dart';
import 'package:tilawa_core/network/network_info.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

/// Manual GetIt registrations for `core`.
class CoreDi {
  CoreDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<UiVisibilityCubit>(
      UiVisibilityCubit.new,
    );
    getIt.registerLazySingletonIfAbsent<AndroidAdhanAlarmPlayer>(
      AndroidAdhanAlarmPlayer.new,
    );
    getIt.registerLazySingletonIfAbsent<ProcessIdProvider>(
      () => const ProcessIdProvider(),
    );
    getIt.registerLazySingletonIfAbsent<NotificationHandlersInitializer>(
      () => const NotificationHandlersInitializer(),
    );
    getIt.registerLazySingletonIfAbsent<LocationServiceWrapper>(
      LocationServiceWrapper.new,
    );
    getIt.registerLazySingletonIfAbsent<QiblaServiceWrapper>(
      QiblaServiceWrapper.new,
    );
    getIt.registerLazySingletonIfAbsent<HiveReadiness>(
      HiveReadinessGate.new,
    );
    getIt.registerLazySingletonIfAbsent<NavigationService>(
      NavigationServiceImpl.new,
    );
    getIt.registerLazySingletonIfAbsent<CrashlyticsService>(
      () => FirebaseCrashlyticsServiceImpl(getIt<FirebaseCrashlytics>()),
    );
    getIt.registerLazySingletonIfAbsent<NotificationPermissionService>(
      () => NotificationPermissionService(
        getIt<SharedPreferencesAsync>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<ServerActionGuard>(
      () => ServerActionGuard(getIt<NetworkInfo>()),
    );
    getIt.registerLazySingletonIfAbsent<QuranAssetsPrefetchPolicyService>(
      () => QuranAssetsPrefetchPolicyService.fromPreferences(
        getIt<SharedPreferencesAsync>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<DeviceTokenService>(
      () => DeviceTokenServiceImpl(getIt<FirebaseMessaging>()),
    );
    getIt.registerLazySingletonIfAbsent<AnalyticsInitializationService>(
      () => AnalyticsInitializationService(
        getIt<AnalyticsService>(),
        getIt<FirebaseAuth>(),
        getIt<CrashlyticsService>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<FirebaseInitializationService>(
      () => FirebaseInitializationService(
        getIt<SubscriptionCatalogPrefetch>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<NotificationStartupService>(
      () => NotificationStartupServiceImpl(
        getIt<INotificationDispatcher>(),
        getIt<SharedPreferencesAsync>(),
        getIt<ProcessIdProvider>(),
        getIt<NotificationHandlersInitializer>(),
        getIt<IAdhanAlarmPlayer>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<AppStartupReadiness>(
      () => AppStartupReadiness(
        getIt<GetRecitersUseCase>(),
        getIt<GetFavoriteRecitersUseCase>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<StartupLaunchCoordinator>(
      () => StartupLaunchCoordinator(
        getIt<GetSplashNextRouteUseCase>(),
        getIt<PrepareGoogleSignInUseCase>(),
        getIt<AppStartupReadiness>(),
      ),
    );
  }
}
