// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:audio_service/audio_service.dart' as _i87;
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:get_it/get_it.dart' as _i174;
import 'package:google_sign_in/google_sign_in.dart' as _i116;
import 'package:injectable/injectable.dart' as _i526;
import 'package:muzakri/audio_player_handler.dart' as _i320;
import 'package:muzakri/core/di/external_dependencies_module.dart' as _i348;
import 'package:muzakri/core/services/firebase_initialization_service.dart'
    as _i197;
import 'package:muzakri/features/alphabet_scrollbar/presentation/bloc/alphabet_scrollbar_bloc.dart'
    as _i203;
import 'package:muzakri/features/audio_player/presentation/bloc/audio_player_bloc.dart'
    as _i965;
import 'package:muzakri/features/auth/data/repositories/auth_repository_impl.dart'
    as _i494;
import 'package:muzakri/features/auth/domain/repositories/auth_repository.dart'
    as _i538;
import 'package:muzakri/features/auth/domain/usecases/get_current_user.dart'
    as _i205;
import 'package:muzakri/features/auth/domain/usecases/sign_in_with_google.dart'
    as _i410;
import 'package:muzakri/features/auth/domain/usecases/sign_out.dart' as _i95;
import 'package:muzakri/features/auth/presentation/bloc/auth_bloc.dart'
    as _i253;
import 'package:muzakri/features/downloads/data/datasources/downloads_local_datasource.dart'
    as _i811;
import 'package:muzakri/features/downloads/data/repositories/downloads_repository_impl.dart'
    as _i486;
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart'
    as _i775;
import 'package:muzakri/features/downloads/domain/usecases/check_surah_downloaded.dart'
    as _i342;
import 'package:muzakri/features/downloads/domain/usecases/delete_download.dart'
    as _i803;
import 'package:muzakri/features/downloads/domain/usecases/download_surah.dart'
    as _i806;
import 'package:muzakri/features/downloads/domain/usecases/get_downloads_by_reciter.dart'
    as _i682;
import 'package:muzakri/features/downloads/presentation/bloc/downloads_bloc.dart'
    as _i811;
import 'package:muzakri/features/localization/presentation/bloc/localization_bloc.dart'
    as _i413;
import 'package:muzakri/features/premium/data/datasources/premium_local_datasource.dart'
    as _i919;
import 'package:muzakri/features/premium/data/datasources/premium_remote_datasource.dart'
    as _i906;
import 'package:muzakri/features/premium/data/repositories/premium_repository_impl.dart'
    as _i756;
import 'package:muzakri/features/premium/data/services/subscription_plans_service.dart'
    as _i812;
import 'package:muzakri/features/premium/domain/repositories/premium_repository.dart'
    as _i872;
import 'package:muzakri/features/premium/presentation/bloc/premium_bloc.dart'
    as _i504;
import 'package:muzakri/features/reciters/presentation/bloc/reciter_details_bloc.dart'
    as _i447;
import 'package:muzakri/features/reciters/presentation/bloc/reciters_bloc.dart'
    as _i864;
import 'package:muzakri/features/theme/presentation/cubit/theme_cubit.dart'
    as _i52;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final externalDependenciesModule = _$ExternalDependenciesModule();
    gh.factory<_i203.AlphabetScrollbarBloc>(
      () => _i203.AlphabetScrollbarBloc(),
    );
    gh.singleton<_i974.FirebaseFirestore>(
      () => externalDependenciesModule.firestore,
    );
    gh.singleton<_i59.FirebaseAuth>(
      () => externalDependenciesModule.firebaseAuth,
    );
    gh.singleton<_i116.GoogleSignIn>(
      () => externalDependenciesModule.googleSignIn,
    );
    await gh.singletonAsync<_i460.SharedPreferences>(
      () => externalDependenciesModule.sharedPreferences,
      preResolve: true,
    );
    gh.singleton<List<_i87.MediaItem>>(
      () => externalDependenciesModule.mediaItemList(),
    );
    gh.singleton<_i812.SubscriptionPlansService>(
      () => externalDependenciesModule.subscriptionPlansService(
        gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.factory<_i52.ThemeCubit>(
      () => _i52.ThemeCubit(gh<_i460.SharedPreferences>()),
    );
    gh.factory<_i413.LocalizationBloc>(
      () => _i413.LocalizationBloc(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i811.DownloadsLocalDataSource>(
      () => _i811.DownloadsLocalDataSourceImpl(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i919.PremiumLocalDataSource>(
      () => _i919.PremiumLocalDataSourceImpl(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i538.AuthRepository>(
      () => _i494.AuthRepositoryImpl(
        gh<_i59.FirebaseAuth>(),
        gh<_i116.GoogleSignIn>(),
      ),
    );
    gh.lazySingleton<_i906.PremiumRemoteDataSource>(
      () => _i906.PremiumRemoteDataSourceImpl(
        gh<_i974.FirebaseFirestore>(),
        gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.singleton<_i197.FirebaseInitializationService>(
      () => externalDependenciesModule.firebaseInitializationService(
        gh<_i974.FirebaseFirestore>(),
        gh<_i812.SubscriptionPlansService>(),
      ),
    );
    await gh.singletonAsync<_i320.AudioPlayerHandler>(
      () => externalDependenciesModule.audioPlayerHandler(
        gh<List<_i87.MediaItem>>(),
      ),
      preResolve: true,
    );
    gh.factory<_i447.ReciterDetailsBloc>(
      () => _i447.ReciterDetailsBloc(gh<_i320.AudioPlayerHandler>()),
    );
    gh.factory<_i864.RecitersBloc>(
      () => _i864.RecitersBloc(gh<_i320.AudioPlayerHandler>()),
    );
    gh.factory<_i965.AudioPlayerBloc>(
      () => _i965.AudioPlayerBloc(gh<_i320.AudioPlayerHandler>()),
    );
    gh.factory<_i95.SignOut>(() => _i95.SignOut(gh<_i538.AuthRepository>()));
    gh.factory<_i410.SignInWithGoogle>(
      () => _i410.SignInWithGoogle(gh<_i538.AuthRepository>()),
    );
    gh.factory<_i205.GetCurrentUser>(
      () => _i205.GetCurrentUser(gh<_i538.AuthRepository>()),
    );
    gh.lazySingleton<_i775.DownloadsRepository>(
      () => _i486.DownloadsRepositoryImpl(gh<_i811.DownloadsLocalDataSource>()),
    );
    gh.lazySingleton<_i872.PremiumRepository>(
      () => _i756.PremiumRepositoryImpl(
        gh<_i919.PremiumLocalDataSource>(),
        gh<_i906.PremiumRemoteDataSource>(),
      ),
    );
    gh.factory<_i253.AuthBloc>(
      () => _i253.AuthBloc(
        gh<_i410.SignInWithGoogle>(),
        gh<_i95.SignOut>(),
        gh<_i205.GetCurrentUser>(),
      ),
    );
    gh.factory<_i806.DownloadSurah>(
      () => _i806.DownloadSurah(gh<_i775.DownloadsRepository>()),
    );
    gh.factory<_i803.DeleteDownload>(
      () => _i803.DeleteDownload(gh<_i775.DownloadsRepository>()),
    );
    gh.factory<_i342.CheckSurahDownloaded>(
      () => _i342.CheckSurahDownloaded(gh<_i775.DownloadsRepository>()),
    );
    gh.factory<_i682.GetDownloadsByReciter>(
      () => _i682.GetDownloadsByReciter(gh<_i775.DownloadsRepository>()),
    );
    gh.factory<_i504.PremiumBloc>(
      () => _i504.PremiumBloc(gh<_i872.PremiumRepository>()),
    );
    gh.factory<_i811.DownloadsBloc>(
      () => _i811.DownloadsBloc(
        getDownloadsByReciter: gh<_i682.GetDownloadsByReciter>(),
        downloadSurah: gh<_i806.DownloadSurah>(),
        deleteDownload: gh<_i803.DeleteDownload>(),
        downloadsRepository: gh<_i775.DownloadsRepository>(),
        premiumRepository: gh<_i872.PremiumRepository>(),
        audioPlayerHandler: gh<_i320.AudioPlayerHandler>(),
      ),
    );
    return this;
  }
}

class _$ExternalDependenciesModule extends _i348.ExternalDependenciesModule {}
