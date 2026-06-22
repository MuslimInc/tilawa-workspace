import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/features/quran_sessions/di/quran_sessions_backend_config.dart';
import 'package:tilawa/features/quran_sessions/di/quran_sessions_firebase_module.dart';
import 'package:tilawa/features/quran_sessions/di/quran_sessions_mvp_module.dart';
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

  _registerQuranSessionsIfNeeded(config);
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
      QuranSessionsFirebaseModule.register(getIt);
  }
}
