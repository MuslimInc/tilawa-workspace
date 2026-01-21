// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:tilawa_core/network/network_info.dart' as _i464;
import 'package:tilawa_core/network/network_info_impl.dart' as _i571;
import 'package:tilawa_core/presentation/bloc/internet_status/internet_status_bloc.dart'
    as _i516;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt initCore({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.factoryParam<_i464.NetworkInfo, _i571.InternetLookup?, dynamic>(
      (internetLookup, _) => _i571.NetworkInfoImpl(
        gh<_i895.Connectivity>(),
        internetLookup: internetLookup,
      ),
    );
    gh.factory<_i516.InternetStatusBloc>(
      () => _i516.InternetStatusBloc(gh<_i464.NetworkInfo>()),
    );
    return this;
  }
}
