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
import 'package:firebase_analytics/firebase_analytics.dart' as _i398;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:firebase_crashlytics/firebase_crashlytics.dart' as _i141;
import 'package:get_it/get_it.dart' as _i174;
import 'package:google_sign_in/google_sign_in.dart' as _i116;
import 'package:injectable/injectable.dart' as _i526;
import 'package:muzakri/audio_player_handler.dart' as _i320;
import 'package:muzakri/core/di/external_dependencies_module.dart' as _i348;
import 'package:muzakri/core/services/analytics_initialization_service.dart'
    as _i528;
import 'package:muzakri/core/services/analytics_service.dart' as _i557;
import 'package:muzakri/core/services/crashlytics_service.dart' as _i235;
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
import 'package:muzakri/features/auth/domain/usecases/get_current_user_use_case.dart'
    as _i778;
import 'package:muzakri/features/auth/domain/usecases/sign_in_with_google_use_case.dart'
    as _i922;
import 'package:muzakri/features/auth/domain/usecases/sign_out.dart' as _i95;
import 'package:muzakri/features/auth/presentation/bloc/auth_bloc.dart'
    as _i253;
import 'package:muzakri/features/downloads/data/datasources/downloads_local_datasource.dart'
    as _i811;
import 'package:muzakri/features/downloads/data/repositories/downloads_repository_impl.dart'
    as _i486;
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart'
    as _i775;
import 'package:muzakri/features/downloads/domain/usecases/check_surah_downloaded_use_case.dart'
    as _i732;
import 'package:muzakri/features/downloads/domain/usecases/clear_all_downloads_use_case.dart'
    as _i917;
import 'package:muzakri/features/downloads/domain/usecases/delete_download_use_case.dart'
    as _i602;
import 'package:muzakri/features/downloads/domain/usecases/delete_reciter_downloads_use_case.dart'
    as _i242;
import 'package:muzakri/features/downloads/domain/usecases/download_surah_use_case.dart'
    as _i251;
import 'package:muzakri/features/downloads/domain/usecases/get_downloads_by_reciter_use_case.dart'
    as _i748;
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
import 'package:muzakri/features/premium/domain/usecases/cancel_subscription_use_case.dart'
    as _i811;
import 'package:muzakri/features/premium/domain/usecases/check_feature_access_use_case.dart'
    as _i128;
import 'package:muzakri/features/premium/domain/usecases/get_available_plans_use_case.dart'
    as _i415;
import 'package:muzakri/features/premium/domain/usecases/get_premium_status_use_case.dart'
    as _i29;
import 'package:muzakri/features/premium/domain/usecases/purchase_subscription_use_case.dart'
    as _i391;
import 'package:muzakri/features/premium/domain/usecases/restore_subscription_use_case.dart'
    as _i412;
import 'package:muzakri/features/premium/domain/usecases/start_trial_use_case.dart'
    as _i509;
import 'package:muzakri/features/premium/presentation/bloc/premium_bloc.dart'
    as _i504;
import 'package:muzakri/features/reciters/presentation/bloc/reciter_details_bloc.dart'
    as _i447;
import 'package:muzakri/features/reciters/presentation/bloc/reciters_bloc.dart'
    as _i864;
import 'package:muzakri/features/surah/data/repositories/surah_repository_impl.dart'
    as _i724;
import 'package:muzakri/features/surah/domain/repositories/surah_repository.dart'
    as _i797;
import 'package:muzakri/features/surah/domain/usecases/check_surah_download_status_use_case.dart'
    as _i916;
import 'package:muzakri/features/surah/domain/usecases/convert_media_items_to_surahs_use_case.dart'
    as _i772;
import 'package:muzakri/features/surah/domain/usecases/get_surahs_for_reciter_use_case.dart'
    as _i576;
import 'package:muzakri/features/surah/domain/usecases/refresh_surah_download_status_use_case.dart'
    as _i506;
import 'package:muzakri/features/surah/domain/usecases/refresh_surah_status_use_case.dart'
    as _i119;
import 'package:muzakri/features/surah/domain/usecases/update_surah_download_progress_use_case.dart'
    as _i319;
import 'package:muzakri/features/surah/domain/usecases/update_surah_download_status_use_case.dart'
    as _i641;
import 'package:muzakri/features/surah/presentation/bloc/surah_bloc.dart'
    as _i595;
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
    gh.singleton<_i398.FirebaseAnalytics>(
      () => externalDependenciesModule.firebaseAnalytics,
    );
    gh.singleton<_i141.FirebaseCrashlytics>(
      () => externalDependenciesModule.firebaseCrashlytics,
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
    gh.singleton<_i235.CrashlyticsService>(
      () =>
          _i235.FirebaseCrashlyticsServiceImpl(gh<_i141.FirebaseCrashlytics>()),
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
    gh.singleton<_i557.AnalyticsService>(
      () => _i557.FirebaseAnalyticsService(gh<_i398.FirebaseAnalytics>()),
    );
    gh.factory<_i95.SignOut>(() => _i95.SignOut(gh<_i538.AuthRepository>()));
    gh.singleton<_i778.GetCurrentUserUseCase>(
      () => _i778.GetCurrentUserUseCase(gh<_i538.AuthRepository>()),
    );
    gh.singleton<_i922.SignInWithGoogleUseCase>(
      () => _i922.SignInWithGoogleUseCase(gh<_i538.AuthRepository>()),
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
        gh<_i922.SignInWithGoogleUseCase>(),
        gh<_i95.SignOut>(),
        gh<_i778.GetCurrentUserUseCase>(),
      ),
    );
    gh.lazySingleton<_i797.SurahRepository>(
      () => _i724.SurahRepositoryImpl(gh<_i775.DownloadsRepository>()),
    );
    gh.singleton<_i251.DownloadSurahUseCase>(
      () => _i251.DownloadSurahUseCase(gh<_i775.DownloadsRepository>()),
    );
    gh.singleton<_i748.GetDownloadsByReciterUseCase>(
      () => _i748.GetDownloadsByReciterUseCase(gh<_i775.DownloadsRepository>()),
    );
    gh.singleton<_i602.DeleteDownloadUseCase>(
      () => _i602.DeleteDownloadUseCase(gh<_i775.DownloadsRepository>()),
    );
    gh.singleton<_i732.CheckSurahDownloadedUseCase>(
      () => _i732.CheckSurahDownloadedUseCase(gh<_i775.DownloadsRepository>()),
    );
    gh.singleton<_i917.ClearAllDownloadsUseCase>(
      () => _i917.ClearAllDownloadsUseCase(gh<_i775.DownloadsRepository>()),
    );
    gh.singleton<_i242.DeleteReciterDownloadsUseCase>(
      () =>
          _i242.DeleteReciterDownloadsUseCase(gh<_i775.DownloadsRepository>()),
    );
    gh.singleton<_i528.AnalyticsInitializationService>(
      () => _i528.AnalyticsInitializationService(
        gh<_i557.AnalyticsService>(),
        gh<_i59.FirebaseAuth>(),
        gh<_i235.CrashlyticsService>(),
      ),
    );
    await gh.singletonAsync<_i320.AudioPlayerHandler>(
      () => externalDependenciesModule.audioPlayerHandler(
        gh<List<_i87.MediaItem>>(),
        gh<_i557.AnalyticsService>(),
      ),
      preResolve: true,
    );
    gh.singleton<_i509.StartTrialUseCase>(
      () => _i509.StartTrialUseCase(gh<_i872.PremiumRepository>()),
    );
    gh.singleton<_i811.CancelSubscriptionUseCase>(
      () => _i811.CancelSubscriptionUseCase(gh<_i872.PremiumRepository>()),
    );
    gh.singleton<_i391.PurchaseSubscriptionUseCase>(
      () => _i391.PurchaseSubscriptionUseCase(gh<_i872.PremiumRepository>()),
    );
    gh.singleton<_i128.CheckFeatureAccessUseCase>(
      () => _i128.CheckFeatureAccessUseCase(gh<_i872.PremiumRepository>()),
    );
    gh.singleton<_i415.GetAvailablePlansUseCase>(
      () => _i415.GetAvailablePlansUseCase(gh<_i872.PremiumRepository>()),
    );
    gh.singleton<_i412.RestoreSubscriptionUseCase>(
      () => _i412.RestoreSubscriptionUseCase(gh<_i872.PremiumRepository>()),
    );
    gh.singleton<_i29.GetPremiumStatusUseCase>(
      () => _i29.GetPremiumStatusUseCase(gh<_i872.PremiumRepository>()),
    );
    gh.factory<_i811.DownloadsBloc>(
      () => _i811.DownloadsBloc(
        getDownloadsByReciter: gh<_i748.GetDownloadsByReciterUseCase>(),
        downloadSurah: gh<_i251.DownloadSurahUseCase>(),
        deleteDownload: gh<_i602.DeleteDownloadUseCase>(),
        deleteReciterDownloads: gh<_i242.DeleteReciterDownloadsUseCase>(),
        clearAllDownloads: gh<_i917.ClearAllDownloadsUseCase>(),
        downloadsRepository: gh<_i775.DownloadsRepository>(),
        premiumRepository: gh<_i872.PremiumRepository>(),
        audioPlayerHandler: gh<_i320.AudioPlayerHandler>(),
        analyticsService: gh<_i557.AnalyticsService>(),
      ),
    );
    gh.factory<_i864.RecitersBloc>(
      () => _i864.RecitersBloc(gh<_i320.AudioPlayerHandler>()),
    );
    gh.factory<_i965.AudioPlayerBloc>(
      () => _i965.AudioPlayerBloc(gh<_i320.AudioPlayerHandler>()),
    );
    gh.singleton<_i641.UpdateSurahDownloadStatusUseCase>(
      () => _i641.UpdateSurahDownloadStatusUseCase(gh<_i797.SurahRepository>()),
    );
    gh.singleton<_i119.RefreshSurahStatusUseCase>(
      () => _i119.RefreshSurahStatusUseCase(gh<_i797.SurahRepository>()),
    );
    gh.singleton<_i772.ConvertMediaItemsToSurahsUseCase>(
      () => _i772.ConvertMediaItemsToSurahsUseCase(gh<_i797.SurahRepository>()),
    );
    gh.singleton<_i576.GetSurahsForReciterUseCase>(
      () => _i576.GetSurahsForReciterUseCase(gh<_i797.SurahRepository>()),
    );
    gh.singleton<_i916.CheckSurahDownloadStatusUseCase>(
      () => _i916.CheckSurahDownloadStatusUseCase(gh<_i797.SurahRepository>()),
    );
    gh.singleton<_i506.RefreshSurahDownloadStatusUseCase>(
      () =>
          _i506.RefreshSurahDownloadStatusUseCase(gh<_i797.SurahRepository>()),
    );
    gh.singleton<_i319.UpdateSurahDownloadProgressUseCase>(
      () =>
          _i319.UpdateSurahDownloadProgressUseCase(gh<_i797.SurahRepository>()),
    );
    gh.factory<_i595.SurahBloc>(
      () => _i595.SurahBloc(
        gh<_i576.GetSurahsForReciterUseCase>(),
        gh<_i641.UpdateSurahDownloadStatusUseCase>(),
        gh<_i319.UpdateSurahDownloadProgressUseCase>(),
        gh<_i916.CheckSurahDownloadStatusUseCase>(),
        gh<_i119.RefreshSurahStatusUseCase>(),
      ),
    );
    gh.factory<_i504.PremiumBloc>(
      () => _i504.PremiumBloc(
        gh<_i29.GetPremiumStatusUseCase>(),
        gh<_i391.PurchaseSubscriptionUseCase>(),
        gh<_i811.CancelSubscriptionUseCase>(),
        gh<_i412.RestoreSubscriptionUseCase>(),
        gh<_i509.StartTrialUseCase>(),
        gh<_i415.GetAvailablePlansUseCase>(),
        gh<_i128.CheckFeatureAccessUseCase>(),
        gh<_i557.AnalyticsService>(),
      ),
    );
    gh.factory<_i447.ReciterDetailsBloc>(
      () => _i447.ReciterDetailsBloc(
        gh<_i320.AudioPlayerHandler>(),
        gh<_i772.ConvertMediaItemsToSurahsUseCase>(),
        gh<_i506.RefreshSurahDownloadStatusUseCase>(),
      ),
    );
    return this;
  }
}

class _$ExternalDependenciesModule extends _i348.ExternalDependenciesModule {}
