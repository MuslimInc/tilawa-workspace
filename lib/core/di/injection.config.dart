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
import 'package:credential_manager/credential_manager.dart' as _i614;
import 'package:dio/dio.dart' as _i361;
import 'package:firebase_analytics/firebase_analytics.dart' as _i398;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:firebase_crashlytics/firebase_crashlytics.dart' as _i141;
import 'package:flutter/services.dart' as _i281;
import 'package:get_it/get_it.dart' as _i174;
import 'package:google_sign_in/google_sign_in.dart' as _i116;
import 'package:injectable/injectable.dart' as _i526;
import 'package:muzakri/core/di/external_dependencies_module.dart' as _i348;
import 'package:muzakri/core/services/analytics_initialization_service.dart'
    as _i528;
import 'package:muzakri/core/services/analytics_service.dart' as _i557;
import 'package:muzakri/core/services/crashlytics_service.dart' as _i235;
import 'package:muzakri/core/services/firebase_initialization_service.dart'
    as _i197;
import 'package:muzakri/core/services/navigation_service.dart' as _i681;
import 'package:muzakri/core/services/notification_permission_service.dart'
    as _i4;
import 'package:muzakri/features/alphabet_scrollbar/presentation/bloc/alphabet_scrollbar_bloc.dart'
    as _i203;
import 'package:muzakri/features/athkar/data/datasources/athkar_local_datasource.dart'
    as _i138;
import 'package:muzakri/features/athkar/data/repositories/athkar_repository_impl.dart'
    as _i1031;
import 'package:muzakri/features/athkar/domain/repositories/athkar_repository.dart'
    as _i496;
import 'package:muzakri/features/athkar/domain/usecases/get_athkar_by_category_use_case.dart'
    as _i982;
import 'package:muzakri/features/athkar/domain/usecases/get_athkar_categories_use_case.dart'
    as _i852;
import 'package:muzakri/features/athkar/presentation/cubit/athkar_cubit.dart'
    as _i757;
import 'package:muzakri/features/audio_player/presentation/bloc/audio_player_bloc.dart'
    as _i965;
import 'package:muzakri/features/auth/data/providers/auth_provider_factory.dart'
    as _i167;
import 'package:muzakri/features/auth/data/providers/credential_manager_auth_provider.dart'
    as _i892;
import 'package:muzakri/features/auth/data/providers/google_auth_provider_impl.dart'
    as _i719;
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
import 'package:muzakri/features/downloads/data/services/batch_download_manager.dart'
    as _i864;
import 'package:muzakri/features/downloads/data/services/download_notification_service.dart'
    as _i288;
import 'package:muzakri/features/downloads/data/services/download_service.dart'
    as _i313;
import 'package:muzakri/features/downloads/data/services/downloads_initialization_service.dart'
    as _i473;
import 'package:muzakri/features/downloads/domain/repositories/batch_download_repository.dart'
    as _i269;
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart'
    as _i775;
import 'package:muzakri/features/downloads/domain/repositories/single_download_repository.dart'
    as _i377;
import 'package:muzakri/features/downloads/domain/usecases/cancel_downloads_for_reciter_use_case.dart'
    as _i242;
import 'package:muzakri/features/downloads/domain/usecases/check_surah_downloaded_use_case.dart'
    as _i732;
import 'package:muzakri/features/downloads/domain/usecases/clear_all_downloads_use_case.dart'
    as _i917;
import 'package:muzakri/features/downloads/domain/usecases/delete_download_use_case.dart'
    as _i602;
import 'package:muzakri/features/downloads/domain/usecases/delete_reciter_downloads_use_case.dart'
    as _i242;
import 'package:muzakri/features/downloads/domain/usecases/download_all_surahs_use_case.dart'
    as _i317;
import 'package:muzakri/features/downloads/domain/usecases/download_surah_use_case.dart'
    as _i251;
import 'package:muzakri/features/downloads/domain/usecases/get_downloads_by_reciter_use_case.dart'
    as _i748;
import 'package:muzakri/features/downloads/domain/usecases/get_total_downloads_size_use_case.dart'
    as _i22;
import 'package:muzakri/features/downloads/presentation/bloc/downloads_bloc.dart'
    as _i811;
import 'package:muzakri/features/localization/data/datasources/localization_local_datasource.dart'
    as _i322;
import 'package:muzakri/features/localization/data/repositories/localization_repository_impl.dart'
    as _i319;
import 'package:muzakri/features/localization/domain/repositories/localization_repository.dart'
    as _i870;
import 'package:muzakri/features/localization/domain/usecases/get_current_language_use_case.dart'
    as _i724;
import 'package:muzakri/features/localization/domain/usecases/set_language_use_case.dart'
    as _i131;
import 'package:muzakri/features/localization/presentation/bloc/localization_bloc.dart'
    as _i413;
import 'package:muzakri/features/playlists/data/datasources/playlists_local_datasource.dart'
    as _i906;
import 'package:muzakri/features/playlists/data/repositories/playlists_repository_impl.dart'
    as _i452;
import 'package:muzakri/features/playlists/domain/repositories/playlists_repository.dart'
    as _i908;
import 'package:muzakri/features/playlists/domain/usecases/add_item_to_playlist_use_case.dart'
    as _i749;
import 'package:muzakri/features/playlists/domain/usecases/create_playlist_use_case.dart'
    as _i491;
import 'package:muzakri/features/playlists/domain/usecases/delete_playlist_use_case.dart'
    as _i328;
import 'package:muzakri/features/playlists/domain/usecases/get_all_playlists_use_case.dart'
    as _i153;
import 'package:muzakri/features/playlists/domain/usecases/remove_item_from_playlist_use_case.dart'
    as _i608;
import 'package:muzakri/features/playlists/domain/usecases/search_playlists_use_case.dart'
    as _i693;
import 'package:muzakri/features/playlists/domain/usecases/toggle_favorite_playlist_use_case.dart'
    as _i372;
import 'package:muzakri/features/playlists/domain/usecases/update_playlist_use_case.dart'
    as _i748;
import 'package:muzakri/features/playlists/domain/usecases/usecases.dart'
    as _i813;
import 'package:muzakri/features/playlists/presentation/bloc/playlists_bloc.dart'
    as _i559;
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
import 'package:muzakri/features/qibla/data/repositories/qibla_repository_impl.dart'
    as _i130;
import 'package:muzakri/features/qibla/domain/repositories/qibla_repository.dart'
    as _i312;
import 'package:muzakri/features/qibla/domain/usecases/check_location_service_use_case.dart'
    as _i71;
import 'package:muzakri/features/qibla/domain/usecases/get_qibla_direction_use_case.dart'
    as _i263;
import 'package:muzakri/features/qibla/domain/usecases/request_location_permission_use_case.dart'
    as _i978;
import 'package:muzakri/features/qibla/presentation/bloc/qibla_bloc.dart'
    as _i239;
import 'package:muzakri/features/reciters/data/datasources/reciters_local_datasource.dart'
    as _i500;
import 'package:muzakri/features/reciters/data/datasources/reciters_remote_datasource.dart'
    as _i4;
import 'package:muzakri/features/reciters/data/repositories/reciters_repository_impl.dart'
    as _i124;
import 'package:muzakri/features/reciters/domain/repositories/reciters_repository.dart'
    as _i619;
import 'package:muzakri/features/reciters/domain/usecases/get_favorite_reciters_use_case.dart'
    as _i821;
import 'package:muzakri/features/reciters/domain/usecases/get_reciters_use_case.dart'
    as _i785;
import 'package:muzakri/features/reciters/domain/usecases/toggle_favorite_reciter_use_case.dart'
    as _i495;
import 'package:muzakri/features/reciters/presentation/bloc/reciter_details_bloc.dart'
    as _i447;
import 'package:muzakri/features/reciters/presentation/bloc/reciters_bloc.dart'
    as _i864;
import 'package:muzakri/features/reciters/presentation/cubit/favorites_cubit.dart'
    as _i663;
import 'package:muzakri/features/reciters/presentation/cubit/reciter_details_loader_cubit.dart'
    as _i574;
import 'package:muzakri/features/settings/presentation/cubit/settings_cubit.dart'
    as _i727;
import 'package:muzakri/features/splash/domain/usecases/get_splash_next_route_use_case.dart'
    as _i935;
import 'package:muzakri/features/splash/presentation/cubit/splash_cubit.dart'
    as _i127;
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
import 'package:muzakri/shared/audio/audio_player_handler.dart' as _i622;
import 'package:muzakri/shared/services/audio_position_service.dart' as _i828;
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
    gh.factory<_i727.SettingsCubit>(() => _i727.SettingsCubit());
    gh.factory<_i52.ThemeCubit>(() => _i52.ThemeCubit());
    gh.singleton<_i974.FirebaseFirestore>(
      () => externalDependenciesModule.firestore,
    );
    gh.singleton<_i59.FirebaseAuth>(
      () => externalDependenciesModule.firebaseAuth,
    );
    gh.singleton<_i116.GoogleSignIn>(
      () => externalDependenciesModule.googleSignIn,
    );
    gh.singleton<_i614.CredentialManager>(
      () => externalDependenciesModule.credentialManager,
    );
    gh.singleton<_i398.FirebaseAnalytics>(
      () => externalDependenciesModule.firebaseAnalytics,
    );
    gh.singleton<_i141.FirebaseCrashlytics>(
      () => externalDependenciesModule.firebaseCrashlytics,
    );
    gh.singleton<_i460.SharedPreferencesAsync>(
      () => externalDependenciesModule.sharedPreferences,
    );
    gh.singleton<_i313.DownloadService>(
      () => externalDependenciesModule.downloadService,
    );
    gh.singleton<_i281.AssetBundle>(
      () => externalDependenciesModule.assetBundle,
    );
    gh.singleton<_i361.Dio>(() => externalDependenciesModule.dioClient());
    gh.singleton<List<_i87.MediaItem>>(
      () => externalDependenciesModule.mediaItemList(),
    );
    gh.lazySingleton<_i892.CredentialManagerAuthProvider>(
      () => _i892.CredentialManagerAuthProvider(
        gh<_i59.FirebaseAuth>(),
        gh<_i614.CredentialManager>(),
      ),
    );
    gh.singleton<_i812.SubscriptionPlansService>(
      () => externalDependenciesModule.subscriptionPlansService(
        gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i681.NavigationService>(
      () => _i681.NavigationServiceImpl(),
    );
    gh.lazySingleton<_i4.NotificationPermissionService>(
      () =>
          _i4.NotificationPermissionService(gh<_i460.SharedPreferencesAsync>()),
    );
    gh.lazySingleton<_i4.RecitersRemoteDataSource>(
      () => _i4.RecitersRemoteDataSourceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i828.AudioPositionService>(
      () => _i828.AudioPositionServiceImpl(),
    );
    gh.singleton<_i235.CrashlyticsService>(
      () =>
          _i235.FirebaseCrashlyticsServiceImpl(gh<_i141.FirebaseCrashlytics>()),
    );
    gh.lazySingleton<_i811.DownloadsLocalDataSource>(
      () => _i811.DownloadsLocalDataSourceImpl(
        gh<_i460.SharedPreferencesAsync>(),
      ),
    );
    gh.lazySingleton<_i500.RecitersLocalDataSource>(
      () =>
          _i500.RecitersLocalDataSourceImpl(gh<_i460.SharedPreferencesAsync>()),
    );
    gh.lazySingleton<_i322.LocalizationLocalDataSource>(
      () => _i322.LocalizationLocalDataSourceImpl(
        gh<_i460.SharedPreferencesAsync>(),
      ),
    );
    gh.lazySingleton<_i919.PremiumLocalDataSource>(
      () =>
          _i919.PremiumLocalDataSourceImpl(gh<_i460.SharedPreferencesAsync>()),
    );
    gh.lazySingleton<_i312.QiblaRepository>(() => _i130.QiblaRepositoryImpl());
    gh.lazySingleton<_i906.PlaylistsLocalDataSource>(
      () => _i906.PlaylistsLocalDataSourceImpl(
        gh<_i460.SharedPreferencesAsync>(),
      ),
    );
    gh.singleton<_i251.DownloadSurahUseCase>(
      () => _i251.DownloadSurahUseCase(gh<_i377.SingleDownloadRepository>()),
    );
    gh.singleton<_i317.DownloadAllSurahsUseCase>(
      () => _i317.DownloadAllSurahsUseCase(gh<_i269.BatchDownloadRepository>()),
    );
    gh.factory<_i71.CheckLocationServiceUseCase>(
      () => _i71.CheckLocationServiceUseCase(gh<_i312.QiblaRepository>()),
    );
    gh.factory<_i263.GetQiblaDirectionUseCase>(
      () => _i263.GetQiblaDirectionUseCase(gh<_i312.QiblaRepository>()),
    );
    gh.factory<_i978.RequestLocationPermissionUseCase>(
      () => _i978.RequestLocationPermissionUseCase(gh<_i312.QiblaRepository>()),
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
    gh.lazySingleton<_i719.GoogleAuthProviderImpl>(
      () => _i719.GoogleAuthProviderImpl(
        gh<_i59.FirebaseAuth>(),
        gh<_i116.GoogleSignIn>(),
      ),
    );
    gh.lazySingleton<_i619.RecitersRepository>(
      () => _i124.RecitersRepositoryImpl(
        gh<_i4.RecitersRemoteDataSource>(),
        gh<_i500.RecitersLocalDataSource>(),
        gh<_i460.SharedPreferencesAsync>(),
      ),
    );
    gh.factory<_i239.QiblaBloc>(
      () => _i239.QiblaBloc(
        gh<_i263.GetQiblaDirectionUseCase>(),
        gh<_i71.CheckLocationServiceUseCase>(),
        gh<_i978.RequestLocationPermissionUseCase>(),
      ),
    );
    gh.lazySingleton<_i288.DownloadNotificationService>(
      () => _i288.DownloadNotificationService(
        gh<_i619.RecitersRepository>(),
        gh<_i681.NavigationService>(),
      ),
    );
    gh.lazySingleton<_i870.LocalizationRepository>(
      () => _i319.LocalizationRepositoryImpl(
        gh<_i322.LocalizationLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i167.AuthProviderFactory>(
      () => _i167.AuthProviderFactory(
        gh<_i59.FirebaseAuth>(),
        gh<_i116.GoogleSignIn>(),
        gh<_i614.CredentialManager>(),
      ),
    );
    gh.singleton<_i557.AnalyticsService>(
      () => _i557.FirebaseAnalyticsService(gh<_i398.FirebaseAnalytics>()),
    );
    gh.lazySingleton<_i138.AthkarLocalDataSource>(
      () =>
          _i138.AthkarLocalDataSourceImpl(assetBundle: gh<_i281.AssetBundle>()),
    );
    gh.lazySingleton<_i821.GetFavoriteRecitersUseCase>(
      () => _i821.GetFavoriteRecitersUseCase(gh<_i619.RecitersRepository>()),
    );
    gh.lazySingleton<_i495.ToggleFavoriteReciterUseCase>(
      () => _i495.ToggleFavoriteReciterUseCase(gh<_i619.RecitersRepository>()),
    );
    gh.factory<_i574.ReciterDetailsLoaderCubit>(
      () => _i574.ReciterDetailsLoaderCubit(gh<_i619.RecitersRepository>()),
    );
    gh.singleton<_i785.GetRecitersUseCase>(
      () => _i785.GetRecitersUseCase(gh<_i619.RecitersRepository>()),
    );
    gh.singleton<_i724.GetCurrentLanguageUseCase>(
      () => _i724.GetCurrentLanguageUseCase(gh<_i870.LocalizationRepository>()),
    );
    gh.singleton<_i131.SetLanguageUseCase>(
      () => _i131.SetLanguageUseCase(gh<_i870.LocalizationRepository>()),
    );
    gh.lazySingleton<_i908.PlaylistsRepository>(
      () => _i452.PlaylistsRepositoryImpl(gh<_i906.PlaylistsLocalDataSource>()),
    );
    gh.lazySingleton<_i872.PremiumRepository>(
      () => _i756.PremiumRepositoryImpl(
        gh<_i919.PremiumLocalDataSource>(),
        gh<_i906.PremiumRemoteDataSource>(),
      ),
    );
    gh.factory<_i663.FavoritesCubit>(
      () => _i663.FavoritesCubit(
        gh<_i821.GetFavoriteRecitersUseCase>(),
        gh<_i495.ToggleFavoriteReciterUseCase>(),
      ),
    );
    gh.lazySingleton<_i496.AthkarRepository>(
      () => _i1031.AthkarRepositoryImpl(gh<_i138.AthkarLocalDataSource>()),
    );
    await gh.singletonAsync<_i622.AudioPlayerHandler>(
      () => externalDependenciesModule.audioPlayerHandler(
        gh<List<_i87.MediaItem>>(),
        gh<_i557.AnalyticsService>(),
        gh<_i460.SharedPreferencesAsync>(),
        gh<_i619.RecitersRepository>(),
      ),
      preResolve: true,
    );
    gh.singleton<_i749.AddItemToPlaylistUseCase>(
      () => _i749.AddItemToPlaylistUseCase(gh<_i908.PlaylistsRepository>()),
    );
    gh.singleton<_i491.CreatePlaylistUseCase>(
      () => _i491.CreatePlaylistUseCase(gh<_i908.PlaylistsRepository>()),
    );
    gh.singleton<_i328.DeletePlaylistUseCase>(
      () => _i328.DeletePlaylistUseCase(gh<_i908.PlaylistsRepository>()),
    );
    gh.singleton<_i153.GetAllPlaylistsUseCase>(
      () => _i153.GetAllPlaylistsUseCase(gh<_i908.PlaylistsRepository>()),
    );
    gh.singleton<_i608.RemoveItemFromPlaylistUseCase>(
      () =>
          _i608.RemoveItemFromPlaylistUseCase(gh<_i908.PlaylistsRepository>()),
    );
    gh.singleton<_i693.SearchPlaylistsUseCase>(
      () => _i693.SearchPlaylistsUseCase(gh<_i908.PlaylistsRepository>()),
    );
    gh.singleton<_i372.ToggleFavoritePlaylistUseCase>(
      () =>
          _i372.ToggleFavoritePlaylistUseCase(gh<_i908.PlaylistsRepository>()),
    );
    gh.singleton<_i748.UpdatePlaylistUseCase>(
      () => _i748.UpdatePlaylistUseCase(gh<_i908.PlaylistsRepository>()),
    );
    gh.singleton<_i528.AnalyticsInitializationService>(
      () => _i528.AnalyticsInitializationService(
        gh<_i557.AnalyticsService>(),
        gh<_i59.FirebaseAuth>(),
        gh<_i235.CrashlyticsService>(),
      ),
    );
    gh.lazySingleton<_i864.BatchDownloadManager>(
      () => _i864.BatchDownloadManager(
        gh<_i313.DownloadService>(),
        gh<_i288.DownloadNotificationService>(),
      ),
    );
    gh.lazySingleton<_i538.AuthRepository>(
      () => _i494.AuthRepositoryImpl(gh<_i167.AuthProviderFactory>()),
    );
    gh.factory<_i864.RecitersBloc>(
      () => _i864.RecitersBloc(gh<_i785.GetRecitersUseCase>()),
    );
    gh.factory<_i559.PlaylistsBloc>(
      () => _i559.PlaylistsBloc(
        getAllPlaylistsUseCase: gh<_i813.GetAllPlaylistsUseCase>(),
        createPlaylistUseCase: gh<_i813.CreatePlaylistUseCase>(),
        updatePlaylistUseCase: gh<_i813.UpdatePlaylistUseCase>(),
        deletePlaylistUseCase: gh<_i813.DeletePlaylistUseCase>(),
        addItemToPlaylistUseCase: gh<_i813.AddItemToPlaylistUseCase>(),
        removeItemFromPlaylistUseCase:
            gh<_i813.RemoveItemFromPlaylistUseCase>(),
        searchPlaylistsUseCase: gh<_i813.SearchPlaylistsUseCase>(),
        toggleFavoritePlaylistUseCase:
            gh<_i813.ToggleFavoritePlaylistUseCase>(),
      ),
    );
    gh.singleton<_i811.CancelSubscriptionUseCase>(
      () => _i811.CancelSubscriptionUseCase(gh<_i872.PremiumRepository>()),
    );
    gh.singleton<_i128.CheckFeatureAccessUseCase>(
      () => _i128.CheckFeatureAccessUseCase(gh<_i872.PremiumRepository>()),
    );
    gh.singleton<_i415.GetAvailablePlansUseCase>(
      () => _i415.GetAvailablePlansUseCase(gh<_i872.PremiumRepository>()),
    );
    gh.singleton<_i29.GetPremiumStatusUseCase>(
      () => _i29.GetPremiumStatusUseCase(gh<_i872.PremiumRepository>()),
    );
    gh.singleton<_i391.PurchaseSubscriptionUseCase>(
      () => _i391.PurchaseSubscriptionUseCase(gh<_i872.PremiumRepository>()),
    );
    gh.singleton<_i412.RestoreSubscriptionUseCase>(
      () => _i412.RestoreSubscriptionUseCase(gh<_i872.PremiumRepository>()),
    );
    gh.singleton<_i509.StartTrialUseCase>(
      () => _i509.StartTrialUseCase(gh<_i872.PremiumRepository>()),
    );
    gh.factory<_i413.LocalizationBloc>(
      () => _i413.LocalizationBloc(
        gh<_i724.GetCurrentLanguageUseCase>(),
        gh<_i131.SetLanguageUseCase>(),
      ),
    );
    gh.factory<_i95.SignOut>(() => _i95.SignOut(gh<_i538.AuthRepository>()));
    gh.singleton<_i778.GetCurrentUserUseCase>(
      () => _i778.GetCurrentUserUseCase(gh<_i538.AuthRepository>()),
    );
    gh.singleton<_i922.SignInWithGoogleUseCase>(
      () => _i922.SignInWithGoogleUseCase(gh<_i538.AuthRepository>()),
    );
    gh.factory<_i253.AuthBloc>(
      () => _i253.AuthBloc(
        gh<_i922.SignInWithGoogleUseCase>(),
        gh<_i95.SignOut>(),
        gh<_i778.GetCurrentUserUseCase>(),
      ),
    );
    gh.factory<_i965.AudioPlayerBloc>(
      () => _i965.AudioPlayerBloc(gh<_i622.AudioPlayerHandler>()),
    );
    gh.lazySingleton<_i775.DownloadsRepository>(
      () => _i486.DownloadsRepositoryImpl(
        gh<_i811.DownloadsLocalDataSource>(),
        gh<_i313.DownloadService>(),
        gh<_i864.BatchDownloadManager>(),
      ),
    );
    gh.lazySingleton<_i982.GetAthkarByCategoryUseCase>(
      () => _i982.GetAthkarByCategoryUseCase(gh<_i496.AthkarRepository>()),
    );
    gh.lazySingleton<_i852.GetAthkarCategoriesUseCase>(
      () => _i852.GetAthkarCategoriesUseCase(gh<_i496.AthkarRepository>()),
    );
    gh.factory<_i935.GetSplashNextRouteUseCase>(
      () => _i935.GetSplashNextRouteUseCase(gh<_i778.GetCurrentUserUseCase>()),
    );
    gh.lazySingleton<_i797.SurahRepository>(
      () => _i724.SurahRepositoryImpl(gh<_i775.DownloadsRepository>()),
    );
    gh.factory<_i242.CancelDownloadsForReciterUseCase>(
      () => _i242.CancelDownloadsForReciterUseCase(
        gh<_i775.DownloadsRepository>(),
      ),
    );
    gh.singleton<_i732.CheckSurahDownloadedUseCase>(
      () => _i732.CheckSurahDownloadedUseCase(gh<_i775.DownloadsRepository>()),
    );
    gh.singleton<_i917.ClearAllDownloadsUseCase>(
      () => _i917.ClearAllDownloadsUseCase(gh<_i775.DownloadsRepository>()),
    );
    gh.singleton<_i602.DeleteDownloadUseCase>(
      () => _i602.DeleteDownloadUseCase(gh<_i775.DownloadsRepository>()),
    );
    gh.singleton<_i242.DeleteReciterDownloadsUseCase>(
      () =>
          _i242.DeleteReciterDownloadsUseCase(gh<_i775.DownloadsRepository>()),
    );
    gh.singleton<_i748.GetDownloadsByReciterUseCase>(
      () => _i748.GetDownloadsByReciterUseCase(gh<_i775.DownloadsRepository>()),
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
    gh.factory<_i127.SplashCubit>(
      () => _i127.SplashCubit(gh<_i935.GetSplashNextRouteUseCase>()),
    );
    gh.singleton<_i473.DownloadsInitializationService>(
      () => _i473.DownloadsInitializationService(
        gh<_i775.DownloadsRepository>(),
        gh<_i288.DownloadNotificationService>(),
      ),
    );
    gh.singleton<_i772.ConvertMediaItemsToSurahsUseCase>(
      () => _i772.ConvertMediaItemsToSurahsUseCase(
        gh<_i797.SurahRepository>(),
        gh<_i775.DownloadsRepository>(),
      ),
    );
    gh.singleton<_i506.RefreshSurahDownloadStatusUseCase>(
      () => _i506.RefreshSurahDownloadStatusUseCase(
        gh<_i797.SurahRepository>(),
        gh<_i775.DownloadsRepository>(),
      ),
    );
    gh.singleton<_i916.CheckSurahDownloadStatusUseCase>(
      () => _i916.CheckSurahDownloadStatusUseCase(gh<_i797.SurahRepository>()),
    );
    gh.singleton<_i576.GetSurahsForReciterUseCase>(
      () => _i576.GetSurahsForReciterUseCase(gh<_i797.SurahRepository>()),
    );
    gh.singleton<_i119.RefreshSurahStatusUseCase>(
      () => _i119.RefreshSurahStatusUseCase(gh<_i797.SurahRepository>()),
    );
    gh.singleton<_i319.UpdateSurahDownloadProgressUseCase>(
      () =>
          _i319.UpdateSurahDownloadProgressUseCase(gh<_i797.SurahRepository>()),
    );
    gh.singleton<_i641.UpdateSurahDownloadStatusUseCase>(
      () => _i641.UpdateSurahDownloadStatusUseCase(gh<_i797.SurahRepository>()),
    );
    gh.factory<_i757.AthkarCubit>(
      () => _i757.AthkarCubit(
        gh<_i852.GetAthkarCategoriesUseCase>(),
        gh<_i982.GetAthkarByCategoryUseCase>(),
      ),
    );
    gh.lazySingleton<_i22.GetTotalDownloadsSizeUseCase>(
      () => _i22.GetTotalDownloadsSizeUseCase(gh<_i775.DownloadsRepository>()),
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
    gh.factory<_i811.DownloadsBloc>(
      () => _i811.DownloadsBloc(
        getDownloadsByReciter: gh<_i748.GetDownloadsByReciterUseCase>(),
        downloadSurah: gh<_i251.DownloadSurahUseCase>(),
        deleteDownload: gh<_i602.DeleteDownloadUseCase>(),
        deleteReciterDownloads: gh<_i242.DeleteReciterDownloadsUseCase>(),
        clearAllDownloads: gh<_i917.ClearAllDownloadsUseCase>(),
        getTotalDownloadsSize: gh<_i22.GetTotalDownloadsSizeUseCase>(),
        downloadsRepository: gh<_i775.DownloadsRepository>(),
        premiumRepository: gh<_i872.PremiumRepository>(),
        audioPlayerHandler: gh<_i622.AudioPlayerHandler>(),
        analyticsService: gh<_i557.AnalyticsService>(),
      ),
    );
    gh.factory<_i447.ReciterDetailsBloc>(
      () => _i447.ReciterDetailsBloc(
        gh<_i622.AudioPlayerHandler>(),
        gh<_i772.ConvertMediaItemsToSurahsUseCase>(),
        gh<_i506.RefreshSurahDownloadStatusUseCase>(),
        gh<_i317.DownloadAllSurahsUseCase>(),
        gh<_i242.CancelDownloadsForReciterUseCase>(),
        gh<_i775.DownloadsRepository>(),
      ),
    );
    return this;
  }
}

class _$ExternalDependenciesModule extends _i348.ExternalDependenciesModule {}
