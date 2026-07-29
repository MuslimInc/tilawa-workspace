import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/core/services/hive_readiness.dart';
import 'package:tilawa/features/history/data/datasources/history_local_datasource.dart';
import 'package:tilawa/features/history/data/repositories/history_repository_impl.dart';
import 'package:tilawa/features/history/domain/repositories/history_repository.dart';
import 'package:tilawa/features/history/domain/usecases/get_history_by_reciter_use_case.dart';
import 'package:tilawa/features/history/domain/usecases/usecases.dart';
import 'package:tilawa/features/history/presentation/bloc/history_bloc.dart';

/// Manual GetIt registrations for `history`.
class HistoryDi {
  HistoryDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<HistoryLocalDataSource>(
      () => HistoryLocalDataSourceImpl(
        getIt<HiveInterface>(),
        getIt<HiveReadiness>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<HistoryRepository>(
      () => HistoryRepositoryImpl(getIt<HistoryLocalDataSource>()),
    );
    getIt.registerLazySingletonIfAbsent<AddOrUpdateHistoryUseCase>(
      () => AddOrUpdateHistoryUseCase(getIt<HistoryRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<ClearAllHistoryUseCase>(
      () => ClearAllHistoryUseCase(getIt<HistoryRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<DeleteHistoryUseCase>(
      () => DeleteHistoryUseCase(getIt<HistoryRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<GetAllHistoryUseCase>(
      () => GetAllHistoryUseCase(getIt<HistoryRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<GetHistoryByReciterUseCase>(
      () => GetHistoryByReciterUseCase(getIt<HistoryRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<GetRecentHistoryUseCase>(
      () => GetRecentHistoryUseCase(getIt<HistoryRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<SearchHistoryUseCase>(
      () => SearchHistoryUseCase(getIt<HistoryRepository>()),
    );
    getIt.registerFactoryIfAbsent<HistoryBloc>(
      () => HistoryBloc(
        getIt<GetAllHistoryUseCase>(),
        getIt<GetRecentHistoryUseCase>(),
        getIt<DeleteHistoryUseCase>(),
        getIt<AddOrUpdateHistoryUseCase>(),
        getIt<ClearAllHistoryUseCase>(),
        getIt<SearchHistoryUseCase>(),
      ),
    );
  }
}
