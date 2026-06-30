// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i687;

import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:injectable/injectable.dart' as _i526;
import 'package:tilawa_core/network/network_info.dart' as _i464;
import 'package:tilawa_core/network/network_info_impl.dart' as _i571;
import 'package:tilawa_core/presentation/bloc/internet_status/internet_status_bloc.dart'
    as _i516;
import 'package:tilawa_core/services/interfaces/keep_awake_service.dart'
    as _i951;
import 'package:tilawa_core/services/wakelock_keep_awake_service.dart' as _i874;

class TilawaCorePackageModule extends _i526.MicroPackageModule {
  // initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.factoryParam<_i464.NetworkInfo, _i571.InternetLookup?, dynamic>(
      (
        internetLookup,
        _,
      ) => _i571.NetworkInfoImpl(
        gh<_i895.Connectivity>(),
        internetLookup: internetLookup,
      ),
    );
    gh.lazySingleton<_i951.KeepAwakeService>(
      () => _i874.WakelockKeepAwakeService(),
    );
    gh.factory<_i516.InternetStatusBloc>(
      () => _i516.InternetStatusBloc(gh<_i464.NetworkInfo>()),
    );
  }
}
