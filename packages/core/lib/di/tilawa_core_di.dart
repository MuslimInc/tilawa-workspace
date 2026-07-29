import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

import '../network/network_info.dart';
import '../network/network_info_impl.dart';
import '../presentation/bloc/internet_status/internet_status_bloc.dart';
import '../services/interfaces/keep_awake_service.dart';
import '../services/wakelock_keep_awake_service.dart';

/// Manual GetIt registrations for tilawa_core.
///
/// Host apps must register [Connectivity] before calling [register].
class TilawaCoreDi {
  TilawaCoreDi._();

  static void register(GetIt getIt) {
    if (!getIt.isRegistered<KeepAwakeService>()) {
      getIt.registerLazySingleton<KeepAwakeService>(
        WakelockKeepAwakeService.new,
      );
    }
    if (!getIt.isRegistered<NetworkInfo>()) {
      getIt.registerFactory<NetworkInfo>(
        () => NetworkInfoImpl(getIt<Connectivity>()),
      );
    }
    if (!getIt.isRegistered<InternetStatusBloc>()) {
      getIt.registerFactory<InternetStatusBloc>(
        () => InternetStatusBloc(getIt<NetworkInfo>()),
      );
    }
  }
}
