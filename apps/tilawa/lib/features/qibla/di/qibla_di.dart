import 'package:get_it/get_it.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/core/wrappers/location_service_wrapper.dart';
import 'package:tilawa/core/wrappers/qibla_service_wrapper.dart';
import 'package:tilawa/features/qibla/data/datasources/qibla_data_source.dart';
import 'package:tilawa/features/qibla/data/repositories/qibla_repository_impl.dart';
import 'package:tilawa/features/qibla/domain/repositories/qibla_repository.dart';
import 'package:tilawa/features/qibla/domain/usecases/check_location_service_use_case.dart';
import 'package:tilawa/features/qibla/domain/usecases/get_qibla_direction_use_case.dart';
import 'package:tilawa/features/qibla/domain/usecases/request_location_permission_use_case.dart';
import 'package:tilawa/features/qibla/presentation/bloc/qibla_bloc.dart';

/// Manual GetIt registrations for `qibla`.
class QiblaDi {
  QiblaDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<QiblaDataSource>(
      () => QiblaDataSourceImpl(
        getIt<LocationServiceWrapper>(),
        getIt<QiblaServiceWrapper>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<QiblaRepository>(
      () => QiblaRepositoryImpl(getIt<QiblaDataSource>()),
    );
    getIt.registerFactoryIfAbsent<CheckLocationServiceUseCase>(
      () => CheckLocationServiceUseCase(getIt<QiblaRepository>()),
    );
    getIt.registerFactoryIfAbsent<GetQiblaDirectionUseCase>(
      () => GetQiblaDirectionUseCase(getIt<QiblaRepository>()),
    );
    getIt.registerFactoryIfAbsent<RequestLocationPermissionUseCase>(
      () => RequestLocationPermissionUseCase(getIt<QiblaRepository>()),
    );
    getIt.registerFactoryIfAbsent<QiblaBloc>(
      () => QiblaBloc(
        getIt<GetQiblaDirectionUseCase>(),
        getIt<CheckLocationServiceUseCase>(),
        getIt<RequestLocationPermissionUseCase>(),
      ),
    );
  }
}
