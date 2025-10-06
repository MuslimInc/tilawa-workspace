import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
// Audio Service
import 'package:muzakri/audio_player_handler.dart';
import 'package:muzakri/audio_player_handler_impl.dart';
// Blocs
import 'package:muzakri/features/alphabet_scrollbar/presentation/bloc/alphabet_scrollbar_bloc.dart';
import 'package:muzakri/features/audio_player/presentation/bloc/audio_player_bloc.dart';
// Features - Downloads
import 'package:muzakri/features/downloads/data/datasources/downloads_local_datasource.dart';
import 'package:muzakri/features/downloads/data/repositories/downloads_repository_impl.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:muzakri/features/downloads/domain/usecases/check_surah_downloaded.dart';
import 'package:muzakri/features/downloads/domain/usecases/delete_download.dart';
import 'package:muzakri/features/downloads/domain/usecases/download_surah.dart';
import 'package:muzakri/features/downloads/domain/usecases/get_downloads_by_reciter.dart';
import 'package:muzakri/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:muzakri/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:muzakri/features/reciters/presentation/bloc/reciter_details_bloc.dart';
import 'package:muzakri/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  // Audio Service initialization
  final audioPlayerHandlerImpl = AudioPlayerHandlerImpl(newList: []);
  sl.registerSingleton<AudioPlayerHandlerImpl>(audioPlayerHandlerImpl);

  final audioHandler = await AudioService.init(
    builder: () => sl<AudioPlayerHandlerImpl>(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.ryanheise.myapp.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    ),
  );
  sl.registerSingleton<AudioPlayerHandler>(audioHandler);

  // External dependencies
  sl.registerLazySingleton(() => Dio());
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPrefs);

  // Data sources
  sl.registerLazySingleton<DownloadsLocalDataSource>(
    () => DownloadsLocalDataSourceImpl(),
  );

  // Repositories
  sl.registerLazySingleton<DownloadsRepository>(
    () => DownloadsRepositoryImpl(localDataSource: sl(), dio: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetDownloadsByReciter(sl()));
  sl.registerLazySingleton(() => DownloadSurah(sl()));
  sl.registerLazySingleton(() => DeleteDownload(sl()));
  sl.registerLazySingleton(() => CheckSurahDownloaded(sl()));

  // Blocs
  sl.registerFactory<LocalizationBloc>(() => LocalizationBloc());
  sl.registerFactory<RecitersBloc>(() => RecitersBloc());
  sl.registerFactory<ReciterDetailsBloc>(() => ReciterDetailsBloc());
  sl.registerFactory<AlphabetScrollbarBloc>(() => AlphabetScrollbarBloc());
  sl.registerFactory<AudioPlayerBloc>(
    () => AudioPlayerBloc(audioHandler: sl<AudioPlayerHandler>()),
  );
  sl.registerFactory(
    () => DownloadsBloc(
      getDownloadsByReciter: sl(),
      downloadSurah: sl(),
      deleteDownload: sl(),
      downloadsRepository: sl(),
    ),
  );
}
