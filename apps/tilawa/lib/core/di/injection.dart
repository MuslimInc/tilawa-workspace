import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa_core/di/injection.module.dart';
import 'package:tilawa_core/network/network_info.dart';

import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

/// Ensures app + core services are registered in [getIt].
///
/// [tilawa_core] is wired via [externalPackageModulesBefore] (injectable 3.x;
/// `includeMicroPackages` was removed).
@InjectableInit(
  externalPackageModulesBefore: [ExternalModule(TilawaCorePackageModule)],
)
Future<void> configureDependencies({AppLaunchConfig? launchConfig}) async {
  if (getIt.isRegistered<NetworkInfo>()) {
    return;
  }

  final AppLaunchConfig config =
      launchConfig ??
      (getIt.isRegistered<AppLaunchConfig>() ? getIt<AppLaunchConfig>() : null) ??
      AppLaunchConfig.fromEnvironment();

  // Failed or partial init left registrations behind without a full graph.
  if (getIt.isRegistered<AppLaunchConfig>() && !getIt.isRegistered<NetworkInfo>()) {
    await getIt.reset();
  }

  if (getIt.isRegistered<AppLaunchConfig>()) {
    getIt.unregister<AppLaunchConfig>();
  }
  getIt.registerSingleton<AppLaunchConfig>(config);

  await getIt.init();

  if (!getIt.isRegistered<NetworkInfo>()) {
    throw StateError(
      'NetworkInfo was not registered after getIt.init(). '
      'Run: dart run build_runner build',
    );
  }
}
