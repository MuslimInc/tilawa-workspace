import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/auth/domain/usecases/sync_user_language_preference_use_case.dart';
import 'package:tilawa/features/localization/data/datasources/localization_local_datasource.dart';
import 'package:tilawa/features/localization/data/repositories/localization_repository_impl.dart';
import 'package:tilawa/features/localization/domain/repositories/localization_repository.dart';
import 'package:tilawa/features/localization/domain/usecases/get_current_language_use_case.dart';
import 'package:tilawa/features/localization/domain/usecases/set_language_use_case.dart';
import 'package:tilawa/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';

/// Manual GetIt registrations for `localization`.
class LocalizationDi {
  LocalizationDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<LocalizationLocalDataSource>(
      () => LocalizationLocalDataSourceImpl(
        getIt<SharedPreferencesAsync>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<LocalizationRepository>(
      () => LocalizationRepositoryImpl(
        getIt<LocalizationLocalDataSource>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<GetCurrentLanguageUseCase>(
      () => GetCurrentLanguageUseCase(getIt<LocalizationRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<SetLanguageUseCase>(
      () => SetLanguageUseCase(getIt<LocalizationRepository>()),
    );
    getIt.registerFactoryIfAbsent<LocalizationBloc>(
      () => LocalizationBloc(
        getIt<GetCurrentLanguageUseCase>(),
        getIt<SetLanguageUseCase>(),
        getIt<GetRecitersUseCase>(),
        getIt<SyncUserLanguagePreferenceUseCase>(),
      ),
    );
  }
}
