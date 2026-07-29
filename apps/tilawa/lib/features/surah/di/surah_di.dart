import 'package:get_it/get_it.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:tilawa/features/reciters/domain/repositories/reciters_repository.dart';
import 'package:tilawa/features/surah/data/repositories/surah_repository_impl.dart';
import 'package:tilawa/features/surah/domain/repositories/surah_repository.dart';
import 'package:tilawa/features/surah/domain/usecases/check_surah_download_status_use_case.dart';
import 'package:tilawa/features/surah/domain/usecases/convert_audio_entities_to_surahs_use_case.dart';
import 'package:tilawa/features/surah/domain/usecases/get_surahs_for_reciter_use_case.dart';
import 'package:tilawa/features/surah/domain/usecases/refresh_surah_download_status_use_case.dart';
import 'package:tilawa/features/surah/domain/usecases/refresh_surah_status_use_case.dart';
import 'package:tilawa/features/surah/domain/usecases/update_surah_download_progress_use_case.dart';
import 'package:tilawa/features/surah/domain/usecases/update_surah_download_status_use_case.dart';
import 'package:tilawa/features/surah/presentation/bloc/surah_bloc.dart';

/// Manual GetIt registrations for `surah`.
class SurahDi {
  SurahDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<SurahRepository>(
      SurahRepositoryImpl.new,
    );
    getIt.registerLazySingletonIfAbsent<GetSurahsForReciterUseCase>(
      () => GetSurahsForReciterUseCase(getIt<SurahRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<UpdateSurahDownloadProgressUseCase>(
      () => UpdateSurahDownloadProgressUseCase(getIt<SurahRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<UpdateSurahDownloadStatusUseCase>(
      () => UpdateSurahDownloadStatusUseCase(getIt<SurahRepository>()),
    );
    getIt.registerFactoryIfAbsent<ConvertAudioEntitiesToSurahsUseCase>(
      () => ConvertAudioEntitiesToSurahsUseCase(
        getIt<SurahRepository>(),
        getIt<DownloadsRepository>(),
        getIt<RecitersRepository>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<CheckSurahDownloadStatusUseCase>(
      () => CheckSurahDownloadStatusUseCase(
        getIt<SurahRepository>(),
        getIt<DownloadsRepository>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<RefreshSurahDownloadStatusUseCase>(
      () => RefreshSurahDownloadStatusUseCase(
        getIt<SurahRepository>(),
        getIt<DownloadsRepository>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<RefreshSurahStatusUseCase>(
      () => RefreshSurahStatusUseCase(
        getIt<SurahRepository>(),
        getIt<DownloadsRepository>(),
      ),
    );
    getIt.registerFactoryIfAbsent<SurahBloc>(
      () => SurahBloc(
        getIt<GetSurahsForReciterUseCase>(),
        getIt<UpdateSurahDownloadStatusUseCase>(),
        getIt<UpdateSurahDownloadProgressUseCase>(),
        getIt<CheckSurahDownloadStatusUseCase>(),
        getIt<RefreshSurahStatusUseCase>(),
      ),
    );
  }
}
