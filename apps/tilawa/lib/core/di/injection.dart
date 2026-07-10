import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/features/auth/device_registry_feature_flags.dart';
import 'package:tilawa/features/genui_assistant/di/genui_assistant_module.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_platform_config_data_source.dart';
import 'package:tilawa/features/quran_sessions/data/local/shared_preferences_platform_config_data_source.dart';
import 'package:tilawa/features/quran_sessions/data/quran_sessions_platform_config_repository.dart';
import 'package:tilawa/features/quran_sessions/di/quran_sessions_backend_config.dart';
import 'package:tilawa/features/quran_sessions/di/quran_sessions_firebase_module.dart';
import 'package:tilawa/features/quran_sessions/di/quran_sessions_mvp_module.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_platform_config_store.dart';
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:tilawa_core/di/injection.module.dart';
import 'package:tilawa_core/network/network_info.dart';

import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

/// True when injectable core services finished registering.
bool get isCoreDependencyGraphReady =>
    getIt.isRegistered<NetworkInfo>() && getIt.isRegistered<SettingsCubit>();

/// True when tilawa_core, injectable graph, and Quran Sessions are wired.
bool get isDependencyGraphReady =>
    isCoreDependencyGraphReady &&
    getIt.isRegistered<GetCurrentUserTeacherCapabilityUseCase>();

/// Ensures app + core services are registered in [getIt].
///
/// [tilawa_core] is wired via [externalPackageModulesBefore] (injectable 3.x;
/// `includeMicroPackages` was removed).
@InjectableInit(
  externalPackageModulesBefore: [ExternalModule(TilawaCorePackageModule)],
)
Future<void> configureDependencies({AppLaunchConfig? launchConfig}) async {
  if (isDependencyGraphReady) {
    return;
  }

  final AppLaunchConfig config =
      launchConfig ??
      (getIt.isRegistered<AppLaunchConfig>()
          ? getIt<AppLaunchConfig>()
          : null) ??
      AppLaunchConfig.fromEnvironment();

  // Failed or partial init left registrations behind without a full graph.
  if (getIt.isRegistered<NetworkInfo>() &&
      !getIt.isRegistered<SettingsCubit>()) {
    await getIt.reset();
  } else if (getIt.isRegistered<AppLaunchConfig>() &&
      !getIt.isRegistered<NetworkInfo>()) {
    await getIt.reset();
  }

  if (getIt.isRegistered<AppLaunchConfig>()) {
    getIt.unregister<AppLaunchConfig>();
  }
  getIt.registerSingleton<AppLaunchConfig>(config);
  // Register the multi-device-login predicate so injectable-resolved
  // constructors (AuthBloc, SessionValidityCubit, SyncDeviceTokenUseCase)
  // receive the real flag reader. The typedef is required because
  // injectable_generator cannot resolve inline `bool Function()` types.
  if (!getIt.isRegistered<MultiDeviceLoginEnabledPredicate>()) {
    getIt.registerSingleton<MultiDeviceLoginEnabledPredicate>(
      isMultiDeviceLoginEnabled,
    );
  }
  if (kDebugMode) {
    debugPrint(
      '[AppLaunchConfig] distribution=${const String.fromEnvironment('TILAWA_DISTRIBUTION', defaultValue: 'local')} '
      'firebaseInit=${config.firebaseInit}',
    );
  }

  if (!isCoreDependencyGraphReady) {
    await getIt.init();

    if (!getIt.isRegistered<NetworkInfo>()) {
      throw StateError(
        'NetworkInfo was not registered after getIt.init(). '
        'Run: melos run gen (from workspace root)',
      );
    }
    if (!getIt.isRegistered<SettingsCubit>()) {
      throw StateError(
        'SettingsCubit was not registered after getIt.init(). '
        'Run: melos run gen (from workspace root)',
      );
    }
  }

  await _registerQuranSessionsPlatformConfig(config);
  _registerQuranSessionsIfNeeded(config);
  GenUiAssistantModule.register(getIt, config: config);
}

Future<void> _registerQuranSessionsPlatformConfig(
  AppLaunchConfig config,
) async {
  if (!getIt.isRegistered<QuranSessionsPlatformConfigStore>()) {
    getIt.registerSingleton<QuranSessionsPlatformConfigStore>(
      QuranSessionsPlatformConfigStore(),
    );
  }
  if (!getIt.isRegistered<SharedPreferencesPlatformConfigDataSource>()) {
    getIt.registerLazySingleton<SharedPreferencesPlatformConfigDataSource>(
      () => SharedPreferencesPlatformConfigDataSource(
        getIt<SharedPreferencesAsync>(),
      ),
    );
  }
  if (!getIt.isRegistered<FirestorePlatformConfigDataSource>() &&
      config.firebaseInit) {
    getIt.registerLazySingleton<FirestorePlatformConfigDataSource>(
      () => FirestorePlatformConfigDataSource(getIt<FirebaseFirestore>()),
    );
  }
  if (!getIt.isRegistered<QuranSessionsPlatformConfigRepository>()) {
    getIt.registerLazySingleton<QuranSessionsPlatformConfigRepository>(
      () => QuranSessionsPlatformConfigRepository(
        remoteDataSource:
            getIt.isRegistered<FirestorePlatformConfigDataSource>()
            ? getIt<FirestorePlatformConfigDataSource>()
            : null,
        localDataSource: getIt<SharedPreferencesPlatformConfigDataSource>(),
        store: getIt<QuranSessionsPlatformConfigStore>(),
      ),
    );
  }

  await getIt<QuranSessionsPlatformConfigRepository>().loadCachedConfig();
}

void _registerQuranSessionsIfNeeded(AppLaunchConfig config) {
  if (getIt.isRegistered<GetCurrentUserTeacherCapabilityUseCase>()) {
    return;
  }

  final backendMode = quranSessionsBackendModeFromEnvironment(
    firebaseInitEnabled: config.firebaseInit,
  );
  switch (backendMode) {
    case QuranSessionsBackendMode.fake:
      QuranSessionsMvpModule.register(getIt);
    case QuranSessionsBackendMode.firebase:
      QuranSessionsFirebaseModule.register(getIt, launchConfig: config);
  }
}
