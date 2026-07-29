import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/core/services/hive_readiness.dart';
import 'package:tilawa/features/radio/data/datasources/radio_local_datasource.dart';
import 'package:tilawa/features/radio/data/datasources/radio_remote_datasource.dart';
import 'package:tilawa/features/radio/data/repositories/radio_repository_impl.dart';
import 'package:tilawa/features/radio/domain/repositories/radio_repository.dart';
import 'package:tilawa/features/radio/domain/usecases/add_recent_radio_station_use_case.dart';
import 'package:tilawa/features/radio/domain/usecases/get_radio_favorites_use_case.dart';
import 'package:tilawa/features/radio/domain/usecases/get_radio_stations_use_case.dart';
import 'package:tilawa/features/radio/domain/usecases/get_recent_radio_stations_use_case.dart';
import 'package:tilawa/features/radio/domain/usecases/refresh_radio_stations_use_case.dart';
import 'package:tilawa/features/radio/domain/usecases/search_radio_stations_use_case.dart';
import 'package:tilawa/features/radio/domain/usecases/toggle_radio_favorite_use_case.dart';
import 'package:tilawa/features/radio/presentation/cubit/radio_cubit.dart';
import 'package:tilawa_core/services/analytics_service.dart';

/// Manual GetIt registrations for `radio`.
class RadioDi {
  RadioDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<RadioRemoteDataSource>(
      () => RadioRemoteDataSourceImpl(getIt<Dio>()),
    );
    getIt.registerLazySingletonIfAbsent<RadioLocalDataSource>(
      () => RadioLocalDataSourceImpl(
        getIt<HiveInterface>(),
        getIt<HiveReadiness>(),
        getIt<SharedPreferencesAsync>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<RadioRepository>(
      () => RadioRepositoryImpl(
        getIt<RadioRemoteDataSource>(),
        getIt<RadioLocalDataSource>(),
        getIt<Connectivity>(),
        getIt<AnalyticsService>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<AddRecentRadioStationUseCase>(
      () => AddRecentRadioStationUseCase(getIt<RadioRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<GetRadioFavoritesUseCase>(
      () => GetRadioFavoritesUseCase(getIt<RadioRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<GetRadioStationsUseCase>(
      () => GetRadioStationsUseCase(getIt<RadioRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<GetRecentRadioStationsUseCase>(
      () => GetRecentRadioStationsUseCase(getIt<RadioRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<RefreshRadioStationsUseCase>(
      () => RefreshRadioStationsUseCase(getIt<RadioRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<SearchRadioStationsUseCase>(
      () => SearchRadioStationsUseCase(getIt<RadioRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<ToggleRadioFavoriteUseCase>(
      () => ToggleRadioFavoriteUseCase(getIt<RadioRepository>()),
    );
    getIt.registerFactoryIfAbsent<RadioCubit>(
      () => RadioCubit(
        getIt<GetRadioStationsUseCase>(),
        getIt<RefreshRadioStationsUseCase>(),
        getIt<SearchRadioStationsUseCase>(),
        getIt<GetRadioFavoritesUseCase>(),
        getIt<ToggleRadioFavoriteUseCase>(),
        getIt<GetRecentRadioStationsUseCase>(),
        getIt<AddRecentRadioStationUseCase>(),
        getIt<AnalyticsService>(),
        getIt<Connectivity>(),
      ),
    );
  }
}
