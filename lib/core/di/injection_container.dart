import 'package:audio_service/audio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Audio Service
import 'package:muzakri/audio_player_handler.dart';
import 'package:muzakri/audio_player_handler_impl.dart';
import 'package:muzakri/core/services/firebase_initialization_service.dart';
// Blocs
import 'package:muzakri/features/alphabet_scrollbar/presentation/bloc/alphabet_scrollbar_bloc.dart';
import 'package:muzakri/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:muzakri/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:muzakri/features/auth/domain/repositories/auth_repository.dart';
import 'package:muzakri/features/auth/domain/usecases/get_current_user.dart';
import 'package:muzakri/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:muzakri/features/auth/domain/usecases/sign_out.dart';
import 'package:muzakri/features/auth/presentation/bloc/auth_bloc.dart';
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
import 'package:muzakri/features/premium/data/datasources/premium_local_datasource.dart';
import 'package:muzakri/features/premium/data/datasources/premium_remote_datasource.dart';
import 'package:muzakri/features/premium/data/repositories/premium_repository_impl.dart';
import 'package:muzakri/features/premium/data/services/subscription_plans_service.dart';
import 'package:muzakri/features/premium/domain/repositories/premium_repository.dart';
import 'package:muzakri/features/premium/presentation/bloc/premium_bloc.dart';
import 'package:muzakri/features/reciters/presentation/bloc/reciter_details_bloc.dart';
import 'package:muzakri/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:muzakri/features/theme/presentation/cubit/theme_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  // External dependencies - initialize these first as they're needed by others
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  
  // Configure Google Sign-In with proper settings
  sl.registerLazySingleton(() => GoogleSignIn.instance);
  
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPrefs);

  // Audio Service initialization - defer this to avoid blocking startup
  _initializeAudioServiceAsync();

  // Auth
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(firebaseAuth: sl(), googleSignIn: sl()),
  );

  // Data sources
  sl.registerLazySingleton<DownloadsLocalDataSource>(
    () => DownloadsLocalDataSourceImpl(),
  );

  // Premium data sources
  sl.registerLazySingleton<PremiumLocalDataSource>(
    () => PremiumLocalDataSourceImpl(prefs: sl()),
  );
  sl.registerLazySingleton<PremiumRemoteDataSource>(
    () => PremiumRemoteDataSourceImpl(firestore: sl(), auth: sl()),
  );

  // Repositories
  sl.registerLazySingleton<DownloadsRepository>(
    () => DownloadsRepositoryImpl(localDataSource: sl()),
  );

  // Premium repository
  sl.registerLazySingleton<PremiumRepository>(
    () => PremiumRepositoryImpl(localDataSource: sl(), remoteDataSource: sl()),
  );

  // Firebase services
  sl.registerLazySingleton(() => SubscriptionPlansService(firestore: sl()));
  sl.registerLazySingleton(
    () => FirebaseInitializationService(
      firestore: sl(),
      subscriptionPlansService: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetDownloadsByReciter(sl()));
  sl.registerLazySingleton(() => DownloadSurah(sl()));
  sl.registerLazySingleton(() => DeleteDownload(sl()));
  sl.registerLazySingleton(() => CheckSurahDownloaded(sl()));

  // Auth use cases
  sl.registerLazySingleton(() => SignInWithGoogle(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));

  // Blocs
  sl.registerFactory<LocalizationBloc>(() => LocalizationBloc());
  sl.registerFactory<ThemeCubit>(() => ThemeCubit(prefs: sl()));
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
      premiumRepository: sl(),
    ),
  );

  // Premium BLoC
  sl.registerFactory(() => PremiumBloc(premiumRepository: sl()));

  // Auth BLoC
  sl.registerFactory(
    () => AuthBloc(signInWithGoogle: sl(), signOut: sl(), getCurrentUser: sl()),
  );
}

/// Initialize audio service asynchronously to avoid blocking main thread
void _initializeAudioServiceAsync() {
  Future.microtask(() async {
    try {
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
    } catch (e) {
      print('Warning: Could not initialize audio service: $e');
    }
  });
}
