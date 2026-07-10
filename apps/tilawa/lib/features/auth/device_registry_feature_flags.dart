import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';

/// Predicate type for launch-flag checks used as injectable constructor
/// parameters. `injectable_generator` cannot resolve inline `bool Function()`
/// types — a named typedef is required.
typedef MultiDeviceLoginEnabledPredicate = bool Function();

/// Whether the client opts into the non-exclusive device registry
/// (`users/{uid}/devices`) — ADR-008 Phase 0. When on, active-device
/// registration also asks the server to upsert the registry doc; the write is
/// additive and never changes login/session behavior.
///
/// Default off in production, on for staging/local builds. Override with:
/// `--dart-define=TILAWA_LAUNCH_DEVICE_REGISTRY_WRITE_ENABLED=true`
bool isDeviceRegistryWriteEnabled() {
  if (!getIt.isRegistered<AppLaunchConfig>()) {
    return AppLaunchConfig.fromEnvironment().deviceRegistryWriteEnabled;
  }
  return getIt<AppLaunchConfig>().deviceRegistryWriteEnabled;
}

/// Whether the client enables true multi-device login — ADR-008 Phase 1. When
/// on, a superseded session (`session_revoked` / `session_epoch_stale`) no
/// longer forces a whole-app logout. Pairs with the server
/// `MULTI_DEVICE_LOGIN_ENABLED` Functions env gate.
///
/// Default off in production, on for staging/local builds. Override with:
/// `--dart-define=TILAWA_LAUNCH_MULTI_DEVICE_LOGIN_ENABLED=true`
bool isMultiDeviceLoginEnabled() {
  if (!getIt.isRegistered<AppLaunchConfig>()) {
    return AppLaunchConfig.fromEnvironment().multiDeviceLoginEnabled;
  }
  return getIt<AppLaunchConfig>().multiDeviceLoginEnabled;
}
