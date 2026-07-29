import 'package:get_it/get_it.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/audio_player/domain/usecases/audio_player_usecases.dart';
import 'package:tilawa/features/quran_reader/data/adapters/quran_image_preload_status_adapter.dart';
import 'package:tilawa/features/quran_reader/data/datasources/datasources.dart';
import 'package:tilawa/features/quran_reader/data/repositories/quran_font_repository_impl.dart';
import 'package:tilawa/features/quran_reader/data/repositories/quran_reader_repository_impl.dart';
import 'package:tilawa/features/quran_reader/domain/ports/quran_image_preload_status.dart';
import 'package:tilawa/features/quran_reader/domain/repositories/quran_font_repository.dart';
import 'package:tilawa/features/quran_reader/domain/repositories/quran_reader_repository.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/check_fonts_downloaded_use_case.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/download_quran_fonts_use_case.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/load_quran_fonts_to_engine_use_case.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/usecases.dart';
import 'package:tilawa/features/quran_reader/presentation/bloc/quran_font_loader_bloc.dart';
import 'package:tilawa/features/quran_reader/presentation/bloc/quran_reader_bloc.dart';
import 'package:tilawa/features/quran_reader/presentation/cubit/quran_settings_cubit.dart';
import 'package:tilawa/features/quran_reader/presentation/cubit/quran_surah_cubit.dart';

/// Manual GetIt registrations for `quran_reader`.
class QuranReaderDi {
  QuranReaderDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<ReaderSettingsDataSource>(
      () => ReaderSettingsDataSourceImpl(
        getIt<SharedPreferencesAsync>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<QuranImagePreloadStatus>(
      () => const QuranImagePreloadStatusAdapter(),
    );
    getIt.registerLazySingletonIfAbsent<QuranTranslationDataSource>(
      QuranTranslationDataSourceImpl.new,
    );
    getIt.registerLazySingletonIfAbsent<QuranDataSource>(
      QuranDataSourceImpl.new,
    );
    getIt.registerLazySingletonIfAbsent<QuranFontRepository>(
      () => QuranFontRepositoryImpl(getIt<QuranFontService>()),
    );
    getIt.registerLazySingletonIfAbsent<QuranReaderRepository>(
      () => QuranReaderRepositoryImpl(
        getIt<QuranDataSource>(),
        getIt<ReaderSettingsDataSource>(),
        getIt<QuranTranslationDataSource>(),
      ),
    );
    getIt.registerFactoryIfAbsent<UpdateCurrentPageUseCase>(
      () => UpdateCurrentPageUseCase(getIt<QuranFontRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<CheckFontsDownloadedUseCase>(
      () => CheckFontsDownloadedUseCase(getIt<QuranFontRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<DownloadQuranFontsUseCase>(
      () => DownloadQuranFontsUseCase(getIt<QuranFontRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<LoadQuranFontsToEngineUseCase>(
      () => LoadQuranFontsToEngineUseCase(getIt<QuranFontRepository>()),
    );
    getIt.registerFactoryIfAbsent<GetLastReadPositionUseCase>(
      () => GetLastReadPositionUseCase(getIt<QuranReaderRepository>()),
    );
    getIt.registerFactoryIfAbsent<GetQuranPageUseCase>(
      () => GetQuranPageUseCase(getIt<QuranReaderRepository>()),
    );
    getIt.registerFactoryIfAbsent<GetStartPageForSurahUseCase>(
      () => GetStartPageForSurahUseCase(getIt<QuranReaderRepository>()),
    );
    getIt.registerFactoryIfAbsent<GetSurahContentUseCase>(
      () => GetSurahContentUseCase(getIt<QuranReaderRepository>()),
    );
    getIt.registerFactoryIfAbsent<LoadReaderSettingsUseCase>(
      () => LoadReaderSettingsUseCase(getIt<QuranReaderRepository>()),
    );
    getIt.registerFactoryIfAbsent<SaveLastReadPositionUseCase>(
      () => SaveLastReadPositionUseCase(getIt<QuranReaderRepository>()),
    );
    getIt.registerFactoryIfAbsent<SaveReaderSettingsUseCase>(
      () => SaveReaderSettingsUseCase(getIt<QuranReaderRepository>()),
    );
    getIt.registerFactoryIfAbsent<SearchAyahsUseCase>(
      () => SearchAyahsUseCase(getIt<QuranReaderRepository>()),
    );
    getIt.registerFactoryIfAbsent<QuranReaderBloc>(
      () => QuranReaderBloc(
        getIt<GetSurahContentUseCase>(),
        getIt<GetQuranPageUseCase>(),
        getIt<SaveLastReadPositionUseCase>(),
        getIt<GetLastReadPositionUseCase>(),
        getIt<SearchAyahsUseCase>(),
        getIt<GetStartPageForSurahUseCase>(),
      ),
    );
    getIt.registerFactoryIfAbsent<QuranFontLoaderBloc>(
      () => QuranFontLoaderBloc(
        getIt<CheckFontsDownloadedUseCase>(),
        getIt<DownloadQuranFontsUseCase>(),
        getIt<LoadQuranFontsToEngineUseCase>(),
        getIt<UpdateCurrentPageUseCase>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<QuranSettingsCubit>(
      () => QuranSettingsCubit(
        getIt<LoadReaderSettingsUseCase>(),
        getIt<SaveReaderSettingsUseCase>(),
      ),
    );
    getIt.registerFactoryIfAbsent<QuranSurahCubit>(
      () => QuranSurahCubit(
        getIt<GetSurahContentUseCase>(),
        getIt<LoadReaderSettingsUseCase>(),
      ),
    );
    getIt.registerFactoryIfAbsent<PlayAyahAudioUseCase>(
      () => PlayAyahAudioUseCase(getIt<PlayFromQueueUseCase>()),
    );
  }
}
