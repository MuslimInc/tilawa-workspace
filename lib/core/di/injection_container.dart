import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
// Features - Localization
import 'package:muzakri/features/localization/data/datasources/localization_local_datasource.dart';
import 'package:muzakri/features/localization/data/repositories/localization_repository_impl.dart';
import 'package:muzakri/features/localization/domain/repositories/localization_repository.dart';
import 'package:muzakri/features/localization/domain/usecases/get_current_language.dart';
import 'package:muzakri/features/localization/domain/usecases/set_language.dart';
import 'package:muzakri/features/localization/presentation/bloc/localization_bloc.dart';
// Features - Reciters
import 'package:muzakri/features/reciters/data/datasources/reciters_remote_datasource.dart';
import 'package:muzakri/features/reciters/data/repositories/reciters_repository_impl.dart';
import 'package:muzakri/features/reciters/domain/repositories/reciters_repository.dart';
import 'package:muzakri/features/reciters/domain/usecases/get_reciters.dart';
import 'package:muzakri/features/reciters/domain/usecases/get_reciters_by_letter.dart';
import 'package:muzakri/features/reciters/domain/usecases/search_reciters.dart';
import 'package:muzakri/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  // External dependencies
  sl.registerLazySingleton(() => Dio());
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPrefs);

  // Data sources
  sl.registerLazySingleton<RecitersRemoteDataSource>(
    () => RecitersRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<LocalizationLocalDataSource>(
    () => LocalizationLocalDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<RecitersRepository>(
    () => RecitersRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<LocalizationRepository>(
    () => LocalizationRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetReciters(sl()));
  sl.registerLazySingleton(() => SearchReciters(sl()));
  sl.registerLazySingleton(() => GetRecitersByLetter(sl()));
  sl.registerLazySingleton(() => GetCurrentLanguage(sl()));
  sl.registerLazySingleton(() => SetLanguage(sl()));

  // Blocs
  sl.registerFactory(
    () => RecitersBloc(
      getReciters: sl(),
      searchReciters: sl(),
      getRecitersByLetter: sl(),
    ),
  );
  sl.registerFactory(
    () => LocalizationBloc(getCurrentLanguage: sl(), setLanguage: sl()),
  );
}
