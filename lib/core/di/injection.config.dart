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
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:credential_manager/credential_manager.dart' as _i614;
import 'package:dio/dio.dart' as _i361;
import 'package:firebase_analytics/firebase_analytics.dart' as _i398;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:firebase_crashlytics/firebase_crashlytics.dart' as _i141;
import 'package:firebase_messaging/firebase_messaging.dart' as _i892;
import 'package:flutter/services.dart' as _i281;
import 'package:get_it/get_it.dart' as _i174;
import 'package:google_sign_in/google_sign_in.dart' as _i116;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:tilawa/core/di/external_dependencies_module.dart' as _i133;
import 'package:tilawa/core/network/network_info.dart' as _i99;
import 'package:tilawa/core/network/network_info_impl.dart' as _i508;
import 'package:tilawa/core/presentation/bloc/internet_status/internet_status_bloc.dart'
    as _i1072;
import 'package:tilawa/core/services/analytics_initialization_service.dart'
    as _i734;
import 'package:tilawa/core/services/analytics_service.dart' as _i145;
import 'package:tilawa/core/services/athkar_notification_service.dart' as _i35;
import 'package:tilawa/core/services/crashlytics_service.dart' as _i600;
import 'package:tilawa/core/services/device_token_service.dart' as _i172;
import 'package:tilawa/core/services/firebase_analytics_service.dart' as _i495;
import 'package:tilawa/core/services/firebase_initialization_service.dart'
    as _i977;
import 'package:tilawa/core/services/interfaces/athkar_notification_service_interface.dart'
    as _i136;
import 'package:tilawa/core/services/interfaces/notification_dispatcher_interface.dart'
    as _i136;
import 'package:tilawa/core/services/luciq_service.dart' as _i636;
import 'package:tilawa/core/services/navigation_service.dart' as _i628;
import 'package:tilawa/core/services/notification_dispatcher.dart' as _i752;
import 'package:tilawa/core/services/notification_permission_service.dart'
    as _i1039;
import 'package:tilawa/core/services/user_email_service.dart' as _i597;
import 'package:tilawa/core/wrappers/location_service_wrapper.dart' as _i527;
import 'package:tilawa/core/wrappers/qibla_service_wrapper.dart' as _i119;
import 'package:tilawa/features/athkar/data/datasources/athkar_local_datasource.dart'
    as _i650;
import 'package:tilawa/features/athkar/data/repositories/athkar_repository_impl.dart'
    as _i150;
import 'package:tilawa/features/athkar/domain/repositories/athkar_repository.dart'
    as _i652;
import 'package:tilawa/features/athkar/domain/usecases/get_athkar_by_category_use_case.dart'
    as _i210;
import 'package:tilawa/features/athkar/domain/usecases/get_athkar_categories_use_case.dart'
    as _i1069;
import 'package:tilawa/features/athkar/presentation/cubit/athkar_cubit.dart'
    as _i117;
import 'package:tilawa/features/audio_player/data/repositories/audio_player_repository_impl.dart'
    as _i198;
import 'package:tilawa/features/audio_player/domain/repositories/audio_player_repository.dart'
    as _i489;
import 'package:tilawa/features/audio_player/domain/usecases/audio_player_usecases.dart'
    as _i28;
import 'package:tilawa/features/audio_player/domain/usecases/check_audio_playability_use_case.dart'
    as _i702;
import 'package:tilawa/features/audio_player/domain/usecases/get_audio_streams_use_case.dart'
    as _i902;
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart'
    as _i433;
import 'package:tilawa/features/auth/data/auth_service.dart' as _i610;
import 'package:tilawa/features/auth/data/providers/auth_provider_factory.dart'
    as _i399;
import 'package:tilawa/features/auth/data/providers/credential_manager_auth_provider.dart'
    as _i784;
import 'package:tilawa/features/auth/data/providers/google_auth_provider_impl.dart'
    as _i342;
import 'package:tilawa/features/auth/data/repositories/auth_repository_impl.dart'
    as _i946;
import 'package:tilawa/features/auth/data/repositories/user_repository_impl.dart'
    as _i504;
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart'
    as _i742;
import 'package:tilawa/features/auth/domain/repositories/user_repository.dart'
    as _i307;
import 'package:tilawa/features/auth/domain/usecases/get_current_user_use_case.dart'
    as _i561;
import 'package:tilawa/features/auth/domain/usecases/sign_in_with_google_use_case.dart'
    as _i931;
import 'package:tilawa/features/auth/domain/usecases/sign_out.dart' as _i633;
import 'package:tilawa/features/auth/domain/usecases/sync_device_token_use_case.dart'
    as _i648;
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart' as _i447;
import 'package:tilawa/features/downloads/data/datasources/downloads_local_datasource.dart'
    as _i965;
import 'package:tilawa/features/downloads/data/repositories/downloads_repository_impl.dart'
    as _i194;
import 'package:tilawa/features/downloads/data/services/batch_download_manager.dart'
    as _i183;
import 'package:tilawa/features/downloads/data/services/download_notification_service.dart'
    as _i409;
import 'package:tilawa/features/downloads/data/services/download_path_resolver.dart'
    as _i511;
import 'package:tilawa/features/downloads/data/services/download_queue_manager.dart'
    as _i420;
import 'package:tilawa/features/downloads/data/services/download_recovery_service.dart'
    as _i767;
import 'package:tilawa/features/downloads/data/services/download_service_impl.dart'
    as _i139;
import 'package:tilawa/features/downloads/data/services/download_service_interface.dart'
    as _i463;
import 'package:tilawa/features/downloads/data/services/download_status_synchronizer.dart'
    as _i881;
import 'package:tilawa/features/downloads/data/services/download_validator.dart'
    as _i49;
import 'package:tilawa/features/downloads/data/services/downloads_initialization_service.dart'
    as _i671;
import 'package:tilawa/features/downloads/data/services/flutter_downloader_wrapper.dart'
    as _i624;
import 'package:tilawa/features/downloads/data/services/helpers/download_file_helper.dart'
    as _i697;
import 'package:tilawa/features/downloads/data/services/helpers/download_isolate_manager.dart'
    as _i896;
import 'package:tilawa/features/downloads/data/services/helpers/download_status_mapper.dart'
    as _i218;
import 'package:tilawa/features/downloads/di/downloads_module.dart' as _i443;
import 'package:tilawa/features/downloads/domain/repositories/batch_download_repository.dart'
    as _i549;
import 'package:tilawa/features/downloads/domain/repositories/download_query_repository.dart'
    as _i56;
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart'
    as _i373;
import 'package:tilawa/features/downloads/domain/repositories/single_download_repository.dart'
    as _i218;
import 'package:tilawa/features/downloads/domain/services/download_notification_service_interface.dart'
    as _i568;
import 'package:tilawa/features/downloads/domain/usecases/cancel_download_use_case.dart'
    as _i807;
import 'package:tilawa/features/downloads/domain/usecases/cancel_downloads_for_reciter_use_case.dart'
    as _i817;
import 'package:tilawa/features/downloads/domain/usecases/check_download_access_use_case.dart'
    as _i105;
import 'package:tilawa/features/downloads/domain/usecases/check_surah_downloaded_use_case.dart'
    as _i594;
import 'package:tilawa/features/downloads/domain/usecases/clear_all_downloads_use_case.dart'
    as _i823;
import 'package:tilawa/features/downloads/domain/usecases/delete_download_use_case.dart'
    as _i893;
import 'package:tilawa/features/downloads/domain/usecases/delete_reciter_downloads_use_case.dart'
    as _i862;
import 'package:tilawa/features/downloads/domain/usecases/download_all_surahs_use_case.dart'
    as _i645;
import 'package:tilawa/features/downloads/domain/usecases/download_surah_use_case.dart'
    as _i231;
import 'package:tilawa/features/downloads/domain/usecases/get_download_item_use_case.dart'
    as _i822;
import 'package:tilawa/features/downloads/domain/usecases/get_download_status_use_case.dart'
    as _i935;
import 'package:tilawa/features/downloads/domain/usecases/get_downloads_by_reciter_use_case.dart'
    as _i605;
import 'package:tilawa/features/downloads/domain/usecases/get_total_downloads_size_use_case.dart'
    as _i589;
import 'package:tilawa/features/downloads/domain/usecases/get_valid_completed_downloads_use_case.dart'
    as _i274;
import 'package:tilawa/features/downloads/domain/usecases/observe_download_progress_use_case.dart'
    as _i767;
import 'package:tilawa/features/downloads/domain/usecases/observe_global_download_progress_use_case.dart'
    as _i323;
import 'package:tilawa/features/downloads/domain/usecases/observe_reciter_downloads_use_case.dart'
    as _i446;
import 'package:tilawa/features/downloads/domain/usecases/play_all_downloads_use_case.dart'
    as _i868;
import 'package:tilawa/features/downloads/domain/usecases/play_download_use_case.dart'
    as _i912;
import 'package:tilawa/features/downloads/domain/usecases/remove_from_download_queue_use_case.dart'
    as _i204;
import 'package:tilawa/features/downloads/domain/usecases/retry_download_use_case.dart'
    as _i702;
import 'package:tilawa/features/downloads/domain/usecases/validate_downloaded_file_use_case.dart'
    as _i628;
import 'package:tilawa/features/downloads/presentation/bloc/downloads_bloc.dart'
    as _i354;
import 'package:tilawa/features/localization/data/datasources/localization_local_datasource.dart'
    as _i678;
import 'package:tilawa/features/localization/data/repositories/localization_repository_impl.dart'
    as _i116;
import 'package:tilawa/features/localization/domain/repositories/localization_repository.dart'
    as _i67;
import 'package:tilawa/features/localization/domain/usecases/get_current_language_use_case.dart'
    as _i326;
import 'package:tilawa/features/localization/domain/usecases/set_language_use_case.dart'
    as _i586;
import 'package:tilawa/features/localization/presentation/bloc/localization_bloc.dart'
    as _i522;
import 'package:tilawa/features/notifications/data/datasources/notifications_remote_data_source.dart'
    as _i371;
import 'package:tilawa/features/notifications/data/repositories/notifications_repository_impl.dart'
    as _i25;
import 'package:tilawa/features/notifications/domain/repositories/notifications_repository.dart'
    as _i549;
import 'package:tilawa/features/notifications/presentation/services/fcm_service.dart'
    as _i1071;
import 'package:tilawa/features/onboarding/data/repositories/onboarding_repository_impl.dart'
    as _i186;
import 'package:tilawa/features/onboarding/domain/repositories/onboarding_repository.dart'
    as _i958;
import 'package:tilawa/features/onboarding/domain/usecases/check_onboarding_status.dart'
    as _i892;
import 'package:tilawa/features/onboarding/domain/usecases/complete_onboarding.dart'
    as _i995;
import 'package:tilawa/features/onboarding/presentation/cubit/onboarding_cubit.dart'
    as _i338;
import 'package:tilawa/features/playlists/data/datasources/playlists_local_datasource.dart'
    as _i470;
import 'package:tilawa/features/playlists/data/repositories/playlists_repository_impl.dart'
    as _i159;
import 'package:tilawa/features/playlists/domain/repositories/playlists_repository.dart'
    as _i662;
import 'package:tilawa/features/playlists/domain/usecases/add_item_to_playlist_use_case.dart'
    as _i1039;
import 'package:tilawa/features/playlists/domain/usecases/create_playlist_use_case.dart'
    as _i986;
import 'package:tilawa/features/playlists/domain/usecases/delete_playlist_use_case.dart'
    as _i282;
import 'package:tilawa/features/playlists/domain/usecases/get_all_playlists_use_case.dart'
    as _i458;
import 'package:tilawa/features/playlists/domain/usecases/remove_item_from_playlist_use_case.dart'
    as _i329;
import 'package:tilawa/features/playlists/domain/usecases/search_playlists_use_case.dart'
    as _i787;
import 'package:tilawa/features/playlists/domain/usecases/toggle_favorite_playlist_use_case.dart'
    as _i330;
import 'package:tilawa/features/playlists/domain/usecases/update_playlist_use_case.dart'
    as _i603;
import 'package:tilawa/features/playlists/domain/usecases/usecases.dart'
    as _i860;
import 'package:tilawa/features/playlists/presentation/bloc/playlists_bloc.dart'
    as _i137;
import 'package:tilawa/features/premium/data/datasources/premium_local_datasource.dart'
    as _i537;
import 'package:tilawa/features/premium/data/datasources/premium_remote_datasource.dart'
    as _i366;
import 'package:tilawa/features/premium/data/repositories/premium_repository_impl.dart'
    as _i437;
import 'package:tilawa/features/premium/data/services/subscription_plans_service.dart'
    as _i253;
import 'package:tilawa/features/premium/domain/repositories/premium_repository.dart'
    as _i422;
import 'package:tilawa/features/premium/domain/usecases/cancel_subscription_use_case.dart'
    as _i91;
import 'package:tilawa/features/premium/domain/usecases/check_feature_access_use_case.dart'
    as _i995;
import 'package:tilawa/features/premium/domain/usecases/get_available_plans_use_case.dart'
    as _i91;
import 'package:tilawa/features/premium/domain/usecases/get_premium_status_use_case.dart'
    as _i64;
import 'package:tilawa/features/premium/domain/usecases/purchase_subscription_use_case.dart'
    as _i659;
import 'package:tilawa/features/premium/domain/usecases/restore_subscription_use_case.dart'
    as _i497;
import 'package:tilawa/features/premium/domain/usecases/start_trial_use_case.dart'
    as _i644;
import 'package:tilawa/features/premium/presentation/bloc/premium_bloc.dart'
    as _i64;
import 'package:tilawa/features/qibla/data/datasources/qibla_data_source.dart'
    as _i912;
import 'package:tilawa/features/qibla/data/repositories/qibla_repository_impl.dart'
    as _i490;
import 'package:tilawa/features/qibla/domain/repositories/qibla_repository.dart'
    as _i6;
import 'package:tilawa/features/qibla/domain/usecases/check_location_service_use_case.dart'
    as _i144;
import 'package:tilawa/features/qibla/domain/usecases/get_qibla_direction_use_case.dart'
    as _i696;
import 'package:tilawa/features/qibla/domain/usecases/request_location_permission_use_case.dart'
    as _i649;
import 'package:tilawa/features/qibla/presentation/bloc/qibla_bloc.dart'
    as _i275;
import 'package:tilawa/features/reciters/data/datasources/reciters_favorites_datasource.dart'
    as _i775;
import 'package:tilawa/features/reciters/data/datasources/reciters_local_datasource.dart'
    as _i831;
import 'package:tilawa/features/reciters/data/datasources/reciters_remote_datasource.dart'
    as _i259;
import 'package:tilawa/features/reciters/data/repositories/reciters_repository_impl.dart'
    as _i16;
import 'package:tilawa/features/reciters/domain/repositories/reciters_repository.dart'
    as _i1039;
import 'package:tilawa/features/reciters/domain/usecases/get_favorite_reciters_use_case.dart'
    as _i933;
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart'
    as _i362;
import 'package:tilawa/features/reciters/domain/usecases/toggle_favorite_reciter_use_case.dart'
    as _i961;
import 'package:tilawa/features/reciters/presentation/bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart'
    as _i300;
import 'package:tilawa/features/reciters/presentation/bloc/reciter_details_bloc.dart'
    as _i184;
import 'package:tilawa/features/reciters/presentation/bloc/reciter_download_bloc.dart'
    as _i510;
import 'package:tilawa/features/reciters/presentation/bloc/reciters_bloc.dart'
    as _i672;
import 'package:tilawa/features/reciters/presentation/cubit/favorites_cubit.dart'
    as _i301;
import 'package:tilawa/features/reciters/presentation/cubit/reciter_details_loader_cubit.dart'
    as _i498;
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart'
    as _i718;
import 'package:tilawa/features/splash/domain/usecases/get_splash_next_route_use_case.dart'
    as _i712;
import 'package:tilawa/features/splash/presentation/cubit/splash_cubit.dart'
    as _i887;
import 'package:tilawa/features/surah/data/repositories/surah_repository_impl.dart'
    as _i193;
import 'package:tilawa/features/surah/domain/repositories/surah_repository.dart'
    as _i697;
import 'package:tilawa/features/surah/domain/usecases/check_surah_download_status_use_case.dart'
    as _i527;
import 'package:tilawa/features/surah/domain/usecases/convert_audio_entities_to_surahs_use_case.dart'
    as _i405;
import 'package:tilawa/features/surah/domain/usecases/get_surahs_for_reciter_use_case.dart'
    as _i792;
import 'package:tilawa/features/surah/domain/usecases/refresh_surah_download_status_use_case.dart'
    as _i863;
import 'package:tilawa/features/surah/domain/usecases/refresh_surah_status_use_case.dart'
    as _i162;
import 'package:tilawa/features/surah/domain/usecases/update_surah_download_progress_use_case.dart'
    as _i815;
import 'package:tilawa/features/surah/domain/usecases/update_surah_download_status_use_case.dart'
    as _i889;
import 'package:tilawa/features/surah/presentation/bloc/surah_bloc.dart'
    as _i387;
import 'package:tilawa/features/theme/presentation/cubit/theme_cubit.dart'
    as _i884;
import 'package:tilawa/shared/audio/audio_player_handler.dart' as _i563;
import 'package:tilawa/shared/services/audio_position_service.dart' as _i641;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final externalDependenciesModule = _$ExternalDependenciesModule();
    final downloadsModule = _$DownloadsModule();
    gh.factory<_i300.AlphabetScrollbarBloc>(
      () => _i300.AlphabetScrollbarBloc(),
    );
    gh.factory<_i884.ThemeCubit>(() => _i884.ThemeCubit());
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
    gh.singleton<_i892.FirebaseMessaging>(
      () => externalDependenciesModule.firebaseMessaging,
    );
    gh.singleton<_i460.SharedPreferencesAsync>(
      () => externalDependenciesModule.sharedPreferences,
    );
    gh.singleton<_i281.AssetBundle>(
      () => externalDependenciesModule.assetBundle,
    );
    gh.singleton<_i361.Dio>(() => externalDependenciesModule.dioClient());
    gh.singleton<List<_i87.MediaItem>>(
      () => externalDependenciesModule.mediaItemList(),
    );
    gh.lazySingleton<_i895.Connectivity>(
      () => externalDependenciesModule.connectivity,
    );
    gh.lazySingleton<_i527.LocationServiceWrapper>(
      () => _i527.LocationServiceWrapper(),
    );
    gh.lazySingleton<_i119.QiblaServiceWrapper>(
      () => _i119.QiblaServiceWrapper(),
    );
    gh.lazySingleton<_i624.FlutterDownloaderWrapper>(
      () => _i624.FlutterDownloaderWrapper(),
    );
    gh.lazySingleton<_i697.DownloadFileHelper>(
      () => _i697.DownloadFileHelper(),
    );
    gh.lazySingleton<_i896.DownloadIsolateManager>(
      () => _i896.DownloadIsolateManager(),
    );
    gh.lazySingleton<_i218.DownloadStatusMapper>(
      () => _i218.DownloadStatusMapper(),
    );
    gh.lazySingleton<_i463.DownloadServiceInterface>(
      () => _i139.DownloadServiceImpl(
        gh<_i624.FlutterDownloaderWrapper>(),
        gh<_i697.DownloadFileHelper>(),
        gh<_i218.DownloadStatusMapper>(),
        gh<_i896.DownloadIsolateManager>(),
      ),
    );
    gh.lazySingleton<_i958.OnboardingRepository>(
      () => _i186.OnboardingRepositoryImpl(gh<_i460.SharedPreferencesAsync>()),
    );
    gh.lazySingleton<_i831.RecitersLocalDataSource>(
      () =>
          _i831.RecitersLocalDataSourceImpl(gh<_i460.SharedPreferencesAsync>()),
    );
    gh.lazySingleton<_i912.QiblaDataSource>(
      () => _i912.QiblaDataSourceImpl(
        gh<_i527.LocationServiceWrapper>(),
        gh<_i119.QiblaServiceWrapper>(),
      ),
    );
    gh.factoryParam<_i99.NetworkInfo, _i508.InternetLookup?, dynamic>(
      (internetLookup, _) => _i508.NetworkInfoImpl(
        gh<_i895.Connectivity>(),
        internetLookup: internetLookup,
      ),
    );
    gh.lazySingleton<_i628.NavigationService>(
      () => _i628.NavigationServiceImpl(),
    );
    gh.lazySingleton<_i136.INotificationDispatcher>(
      () => _i752.NotificationDispatcher(),
    );
    gh.lazySingleton<_i641.AudioPositionService>(
      () => _i641.AudioPositionServiceImpl(),
    );
    gh.lazySingleton<_i678.LocalizationLocalDataSource>(
      () => _i678.LocalizationLocalDataSourceImpl(
        gh<_i460.SharedPreferencesAsync>(),
      ),
    );
    gh.lazySingleton<_i6.QiblaRepository>(
      () => _i490.QiblaRepositoryImpl(gh<_i912.QiblaDataSource>()),
    );
    gh.lazySingleton<_i965.DownloadsLocalDataSource>(
      () => _i965.DownloadsLocalDataSourceImpl(
        gh<_i460.SharedPreferencesAsync>(),
      ),
    );
    gh.singleton<_i600.CrashlyticsService>(
      () =>
          _i600.FirebaseCrashlyticsServiceImpl(gh<_i141.FirebaseCrashlytics>()),
    );
    gh.singleton<_i636.LuciqService>(() => _i636.LuciqServiceImpl());
    gh.lazySingleton<_i470.PlaylistsLocalDataSource>(
      () => _i470.PlaylistsLocalDataSourceImpl(
        gh<_i460.SharedPreferencesAsync>(),
      ),
    );
    gh.lazySingleton<_i697.SurahRepository>(() => _i193.SurahRepositoryImpl());
    gh.lazySingleton<_i511.DownloadPathResolver>(
      () => _i511.DownloadPathResolver(gh<_i965.DownloadsLocalDataSource>()),
    );
    gh.lazySingleton<_i49.DownloadValidator>(
      () => _i49.DownloadValidator(gh<_i965.DownloadsLocalDataSource>()),
    );
    gh.lazySingleton<_i1039.NotificationPermissionService>(
      () => _i1039.NotificationPermissionService(
        gh<_i460.SharedPreferencesAsync>(),
      ),
    );
    gh.lazySingleton<_i259.RecitersRemoteDataSource>(
      () => _i259.RecitersRemoteDataSourceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i537.PremiumLocalDataSource>(
      () =>
          _i537.PremiumLocalDataSourceImpl(gh<_i460.SharedPreferencesAsync>()),
    );
    gh.lazySingleton<_i67.LocalizationRepository>(
      () => _i116.LocalizationRepositoryImpl(
        gh<_i678.LocalizationLocalDataSource>(),
      ),
    );
    gh.singleton<_i253.SubscriptionPlansService>(
      () => externalDependenciesModule.subscriptionPlansService(
        gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i399.AuthProviderFactory>(
      () => _i399.AuthProviderFactory(
        gh<_i59.FirebaseAuth>(),
        gh<_i116.GoogleSignIn>(),
        gh<_i614.CredentialManager>(),
      ),
    );
    gh.lazySingleton<_i784.CredentialManagerAuthProvider>(
      () => _i784.CredentialManagerAuthProvider(
        gh<_i59.FirebaseAuth>(),
        gh<_i614.CredentialManager>(),
      ),
    );
    gh.lazySingleton<_i371.NotificationsRemoteDataSource>(
      () => _i371.NotificationsRemoteDataSourceImpl(
        gh<_i892.FirebaseMessaging>(),
        gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i307.UserRepository>(
      () => _i504.UserRepositoryImpl(gh<_i974.FirebaseFirestore>()),
    );
    gh.singleton<_i792.GetSurahsForReciterUseCase>(
      () => _i792.GetSurahsForReciterUseCase(gh<_i697.SurahRepository>()),
    );
    gh.singleton<_i815.UpdateSurahDownloadProgressUseCase>(
      () =>
          _i815.UpdateSurahDownloadProgressUseCase(gh<_i697.SurahRepository>()),
    );
    gh.singleton<_i889.UpdateSurahDownloadStatusUseCase>(
      () => _i889.UpdateSurahDownloadStatusUseCase(gh<_i697.SurahRepository>()),
    );
    gh.lazySingleton<_i597.UserEmailService>(
      () => _i597.UserEmailServiceImpl(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i662.PlaylistsRepository>(
      () => _i159.PlaylistsRepositoryImpl(gh<_i470.PlaylistsLocalDataSource>()),
    );
    gh.lazySingleton<_i549.NotificationsRepository>(
      () => _i25.NotificationsRepositoryImpl(
        gh<_i371.NotificationsRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i650.AthkarLocalDataSource>(
      () =>
          _i650.AthkarLocalDataSourceImpl(assetBundle: gh<_i281.AssetBundle>()),
    );
    gh.lazySingleton<_i610.AuthService>(
      () => _i610.AuthService(auth: gh<_i59.FirebaseAuth>()),
    );
    gh.singleton<_i935.GetDownloadStatusUseCase>(
      () =>
          _i935.GetDownloadStatusUseCase(gh<_i463.DownloadServiceInterface>()),
    );
    gh.singleton<_i323.ObserveGlobalDownloadProgressUseCase>(
      () => _i323.ObserveGlobalDownloadProgressUseCase(
        gh<_i463.DownloadServiceInterface>(),
      ),
    );
    gh.lazySingleton<_i172.DeviceTokenService>(
      () => _i172.DeviceTokenServiceImpl(gh<_i892.FirebaseMessaging>()),
    );
    gh.lazySingleton<_i342.GoogleAuthProviderImpl>(
      () => _i342.GoogleAuthProviderImpl(
        gh<_i59.FirebaseAuth>(),
        gh<_i116.GoogleSignIn>(),
      ),
    );
    gh.factory<_i1072.InternetStatusBloc>(
      () => _i1072.InternetStatusBloc(gh<_i99.NetworkInfo>()),
    );
    gh.lazySingleton<_i136.IAthkarNotificationService>(
      () => _i35.AthkarNotificationService(
        gh<_i460.SharedPreferencesAsync>(),
        gh<_i136.INotificationDispatcher>(),
      ),
    );
    gh.lazySingleton<_i366.PremiumRemoteDataSource>(
      () => _i366.PremiumRemoteDataSourceImpl(
        gh<_i974.FirebaseFirestore>(),
        gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.factory<_i648.SyncDeviceTokenUseCase>(
      () => _i648.SyncDeviceTokenUseCase(
        gh<_i307.UserRepository>(),
        gh<_i172.DeviceTokenService>(),
      ),
    );
    gh.singleton<_i145.AnalyticsService>(
      () => _i495.FirebaseAnalyticsService(gh<_i398.FirebaseAnalytics>()),
    );
    gh.lazySingleton<_i775.RecitersFavoritesDataSource>(
      () =>
          _i775.RecitersFavoritesDataSourceImpl(gh<_i974.FirebaseFirestore>()),
    );
    gh.factory<_i892.CheckOnboardingStatus>(
      () => _i892.CheckOnboardingStatus(gh<_i958.OnboardingRepository>()),
    );
    gh.factory<_i995.CompleteOnboarding>(
      () => _i995.CompleteOnboarding(gh<_i958.OnboardingRepository>()),
    );
    gh.lazySingleton<_i652.AthkarRepository>(
      () => _i150.AthkarRepositoryImpl(
        gh<_i650.AthkarLocalDataSource>(),
        gh<_i145.AnalyticsService>(),
      ),
    );
    gh.singleton<_i734.AnalyticsInitializationService>(
      () => _i734.AnalyticsInitializationService(
        gh<_i145.AnalyticsService>(),
        gh<_i59.FirebaseAuth>(),
        gh<_i600.CrashlyticsService>(),
      ),
    );
    gh.factory<_i144.CheckLocationServiceUseCase>(
      () => _i144.CheckLocationServiceUseCase(gh<_i6.QiblaRepository>()),
    );
    gh.factory<_i696.GetQiblaDirectionUseCase>(
      () => _i696.GetQiblaDirectionUseCase(gh<_i6.QiblaRepository>()),
    );
    gh.factory<_i649.RequestLocationPermissionUseCase>(
      () => _i649.RequestLocationPermissionUseCase(gh<_i6.QiblaRepository>()),
    );
    gh.factory<_i338.OnboardingCubit>(
      () => _i338.OnboardingCubit(gh<_i995.CompleteOnboarding>()),
    );
    gh.lazySingleton<_i742.AuthRepository>(
      () => _i946.AuthRepositoryImpl(gh<_i399.AuthProviderFactory>()),
    );
    gh.factory<_i633.SignOut>(() => _i633.SignOut(gh<_i742.AuthRepository>()));
    gh.singleton<_i561.GetCurrentUserUseCase>(
      () => _i561.GetCurrentUserUseCase(gh<_i742.AuthRepository>()),
    );
    gh.lazySingleton<_i1039.RecitersRepository>(
      () => _i16.RecitersRepositoryImpl(
        gh<_i259.RecitersRemoteDataSource>(),
        gh<_i831.RecitersLocalDataSource>(),
        gh<_i775.RecitersFavoritesDataSource>(),
        gh<_i610.AuthService>(),
        gh<_i460.SharedPreferencesAsync>(),
      ),
    );
    gh.lazySingleton<_i210.GetAthkarByCategoryUseCase>(
      () => _i210.GetAthkarByCategoryUseCase(gh<_i652.AthkarRepository>()),
    );
    gh.lazySingleton<_i1069.GetAthkarCategoriesUseCase>(
      () => _i1069.GetAthkarCategoriesUseCase(gh<_i652.AthkarRepository>()),
    );
    gh.lazySingleton<_i422.PremiumRepository>(
      () => _i437.PremiumRepositoryImpl(
        gh<_i537.PremiumLocalDataSource>(),
        gh<_i366.PremiumRemoteDataSource>(),
        gh<_i145.AnalyticsService>(),
      ),
    );
    gh.singleton<_i1039.AddItemToPlaylistUseCase>(
      () => _i1039.AddItemToPlaylistUseCase(gh<_i662.PlaylistsRepository>()),
    );
    gh.singleton<_i986.CreatePlaylistUseCase>(
      () => _i986.CreatePlaylistUseCase(gh<_i662.PlaylistsRepository>()),
    );
    gh.singleton<_i282.DeletePlaylistUseCase>(
      () => _i282.DeletePlaylistUseCase(gh<_i662.PlaylistsRepository>()),
    );
    gh.singleton<_i458.GetAllPlaylistsUseCase>(
      () => _i458.GetAllPlaylistsUseCase(gh<_i662.PlaylistsRepository>()),
    );
    gh.singleton<_i329.RemoveItemFromPlaylistUseCase>(
      () =>
          _i329.RemoveItemFromPlaylistUseCase(gh<_i662.PlaylistsRepository>()),
    );
    gh.singleton<_i787.SearchPlaylistsUseCase>(
      () => _i787.SearchPlaylistsUseCase(gh<_i662.PlaylistsRepository>()),
    );
    gh.singleton<_i330.ToggleFavoritePlaylistUseCase>(
      () =>
          _i330.ToggleFavoritePlaylistUseCase(gh<_i662.PlaylistsRepository>()),
    );
    gh.singleton<_i603.UpdatePlaylistUseCase>(
      () => _i603.UpdatePlaylistUseCase(gh<_i662.PlaylistsRepository>()),
    );
    gh.lazySingleton<_i568.IDownloadNotificationService>(
      () => _i409.DownloadNotificationService(
        gh<_i1039.RecitersRepository>(),
        gh<_i628.NavigationService>(),
        gh<_i136.INotificationDispatcher>(),
      ),
    );
    gh.singleton<_i326.GetCurrentLanguageUseCase>(
      () => _i326.GetCurrentLanguageUseCase(gh<_i67.LocalizationRepository>()),
    );
    gh.singleton<_i586.SetLanguageUseCase>(
      () => _i586.SetLanguageUseCase(gh<_i67.LocalizationRepository>()),
    );
    gh.singleton<_i977.FirebaseInitializationService>(
      () => externalDependenciesModule.firebaseInitializationService(
        gh<_i974.FirebaseFirestore>(),
        gh<_i253.SubscriptionPlansService>(),
      ),
    );
    gh.factory<_i931.SignInWithGoogleUseCase>(
      () => _i931.SignInWithGoogleUseCase(
        gh<_i742.AuthRepository>(),
        gh<_i307.UserRepository>(),
      ),
    );
    gh.factory<_i117.AthkarCubit>(
      () => _i117.AthkarCubit(
        gh<_i1069.GetAthkarCategoriesUseCase>(),
        gh<_i210.GetAthkarByCategoryUseCase>(),
        gh<_i145.AnalyticsService>(),
      ),
    );
    gh.factory<_i712.GetSplashNextRouteUseCase>(
      () => _i712.GetSplashNextRouteUseCase(
        gh<_i561.GetCurrentUserUseCase>(),
        gh<_i892.CheckOnboardingStatus>(),
      ),
    );
    gh.lazySingleton<_i105.CheckDownloadAccessUseCase>(
      () => _i105.CheckDownloadAccessUseCase(gh<_i422.PremiumRepository>()),
    );
    gh.singleton<_i91.CancelSubscriptionUseCase>(
      () => _i91.CancelSubscriptionUseCase(gh<_i422.PremiumRepository>()),
    );
    gh.singleton<_i995.CheckFeatureAccessUseCase>(
      () => _i995.CheckFeatureAccessUseCase(gh<_i422.PremiumRepository>()),
    );
    gh.singleton<_i91.GetAvailablePlansUseCase>(
      () => _i91.GetAvailablePlansUseCase(gh<_i422.PremiumRepository>()),
    );
    gh.singleton<_i64.GetPremiumStatusUseCase>(
      () => _i64.GetPremiumStatusUseCase(gh<_i422.PremiumRepository>()),
    );
    gh.singleton<_i659.PurchaseSubscriptionUseCase>(
      () => _i659.PurchaseSubscriptionUseCase(gh<_i422.PremiumRepository>()),
    );
    gh.singleton<_i497.RestoreSubscriptionUseCase>(
      () => _i497.RestoreSubscriptionUseCase(gh<_i422.PremiumRepository>()),
    );
    gh.singleton<_i644.StartTrialUseCase>(
      () => _i644.StartTrialUseCase(gh<_i422.PremiumRepository>()),
    );
    gh.factory<_i64.PremiumBloc>(
      () => _i64.PremiumBloc(
        gh<_i64.GetPremiumStatusUseCase>(),
        gh<_i659.PurchaseSubscriptionUseCase>(),
        gh<_i91.CancelSubscriptionUseCase>(),
        gh<_i497.RestoreSubscriptionUseCase>(),
        gh<_i644.StartTrialUseCase>(),
        gh<_i91.GetAvailablePlansUseCase>(),
        gh<_i995.CheckFeatureAccessUseCase>(),
      ),
    );
    gh.lazySingleton<_i933.GetFavoriteRecitersUseCase>(
      () => _i933.GetFavoriteRecitersUseCase(gh<_i1039.RecitersRepository>()),
    );
    gh.lazySingleton<_i961.ToggleFavoriteReciterUseCase>(
      () => _i961.ToggleFavoriteReciterUseCase(gh<_i1039.RecitersRepository>()),
    );
    gh.singleton<_i362.GetRecitersUseCase>(
      () => _i362.GetRecitersUseCase(gh<_i1039.RecitersRepository>()),
    );
    gh.factory<_i498.ReciterDetailsLoaderCubit>(
      () => _i498.ReciterDetailsLoaderCubit(gh<_i1039.RecitersRepository>()),
    );
    gh.lazySingleton<_i183.BatchDownloadManager>(
      () => _i183.BatchDownloadManager(
        gh<_i463.DownloadServiceInterface>(),
        gh<_i568.IDownloadNotificationService>(),
      ),
    );
    gh.lazySingleton<_i420.DownloadQueueManager>(
      () => _i420.DownloadQueueManager(
        gh<_i463.DownloadServiceInterface>(),
        gh<_i568.IDownloadNotificationService>(),
      ),
    );
    gh.lazySingleton<_i1071.FCMService>(
      () => _i1071.FCMService(
        gh<_i610.AuthService>(),
        gh<_i648.SyncDeviceTokenUseCase>(),
        gh<_i172.DeviceTokenService>(),
      ),
    );
    gh.factory<_i522.LocalizationBloc>(
      () => _i522.LocalizationBloc(
        gh<_i326.GetCurrentLanguageUseCase>(),
        gh<_i586.SetLanguageUseCase>(),
      ),
    );
    gh.factory<_i137.PlaylistsBloc>(
      () => _i137.PlaylistsBloc(
        getAllPlaylistsUseCase: gh<_i860.GetAllPlaylistsUseCase>(),
        createPlaylistUseCase: gh<_i860.CreatePlaylistUseCase>(),
        updatePlaylistUseCase: gh<_i860.UpdatePlaylistUseCase>(),
        deletePlaylistUseCase: gh<_i860.DeletePlaylistUseCase>(),
        addItemToPlaylistUseCase: gh<_i860.AddItemToPlaylistUseCase>(),
        removeItemFromPlaylistUseCase:
            gh<_i860.RemoveItemFromPlaylistUseCase>(),
        searchPlaylistsUseCase: gh<_i860.SearchPlaylistsUseCase>(),
        toggleFavoritePlaylistUseCase:
            gh<_i860.ToggleFavoritePlaylistUseCase>(),
      ),
    );
    gh.factory<_i718.SettingsCubit>(
      () => _i718.SettingsCubit(gh<_i420.DownloadQueueManager>()),
    );
    gh.factory<_i301.FavoritesCubit>(
      () => _i301.FavoritesCubit(
        gh<_i933.GetFavoriteRecitersUseCase>(),
        gh<_i961.ToggleFavoriteReciterUseCase>(),
      ),
    );
    gh.factory<_i672.RecitersBloc>(
      () => _i672.RecitersBloc(gh<_i362.GetRecitersUseCase>()),
    );
    gh.factory<_i887.SplashCubit>(
      () => _i887.SplashCubit(gh<_i712.GetSplashNextRouteUseCase>()),
    );
    gh.factory<_i275.QiblaBloc>(
      () => _i275.QiblaBloc(
        gh<_i696.GetQiblaDirectionUseCase>(),
        gh<_i144.CheckLocationServiceUseCase>(),
        gh<_i649.RequestLocationPermissionUseCase>(),
      ),
    );
    gh.singleton<_i204.RemoveFromDownloadQueueUseCase>(
      () => _i204.RemoveFromDownloadQueueUseCase(
        gh<_i420.DownloadQueueManager>(),
      ),
    );
    gh.factory<_i447.AuthBloc>(
      () => _i447.AuthBloc(
        gh<_i931.SignInWithGoogleUseCase>(),
        gh<_i633.SignOut>(),
        gh<_i561.GetCurrentUserUseCase>(),
        gh<_i648.SyncDeviceTokenUseCase>(),
      ),
    );
    gh.lazySingleton<_i767.DownloadRecoveryService>(
      () => _i767.DownloadRecoveryService(
        gh<_i463.DownloadServiceInterface>(),
        gh<_i49.DownloadValidator>(),
        gh<_i420.DownloadQueueManager>(),
      ),
    );
    gh.lazySingleton<_i881.DownloadStatusSynchronizer>(
      () => _i881.DownloadStatusSynchronizer(
        gh<_i463.DownloadServiceInterface>(),
        gh<_i767.DownloadRecoveryService>(),
        gh<_i420.DownloadQueueManager>(),
      ),
    );
    gh.lazySingleton<_i373.DownloadsRepository>(
      () => _i194.DownloadsRepositoryImpl(
        gh<_i965.DownloadsLocalDataSource>(),
        gh<_i463.DownloadServiceInterface>(),
        gh<_i183.BatchDownloadManager>(),
        gh<_i511.DownloadPathResolver>(),
        gh<_i881.DownloadStatusSynchronizer>(),
        gh<_i49.DownloadValidator>(),
        gh<_i420.DownloadQueueManager>(),
        gh<_i145.AnalyticsService>(),
        gh<_i99.NetworkInfo>(),
      ),
    );
    gh.singleton<_i671.DownloadsInitializationService>(
      () => _i671.DownloadsInitializationService(
        gh<_i373.DownloadsRepository>(),
        gh<_i568.IDownloadNotificationService>(),
      ),
    );
    gh.singleton<_i527.CheckSurahDownloadStatusUseCase>(
      () => _i527.CheckSurahDownloadStatusUseCase(
        gh<_i697.SurahRepository>(),
        gh<_i373.DownloadsRepository>(),
      ),
    );
    gh.singleton<_i863.RefreshSurahDownloadStatusUseCase>(
      () => _i863.RefreshSurahDownloadStatusUseCase(
        gh<_i697.SurahRepository>(),
        gh<_i373.DownloadsRepository>(),
      ),
    );
    gh.singleton<_i162.RefreshSurahStatusUseCase>(
      () => _i162.RefreshSurahStatusUseCase(
        gh<_i697.SurahRepository>(),
        gh<_i373.DownloadsRepository>(),
      ),
    );
    gh.lazySingleton<_i589.GetTotalDownloadsSizeUseCase>(
      () => _i589.GetTotalDownloadsSizeUseCase(gh<_i373.DownloadsRepository>()),
    );
    gh.lazySingleton<_i822.GetDownloadItemUseCase>(
      () => _i822.GetDownloadItemUseCase(gh<_i373.DownloadsRepository>()),
    );
    gh.lazySingleton<_i702.RetryDownloadUseCase>(
      () => _i702.RetryDownloadUseCase(gh<_i373.DownloadsRepository>()),
    );
    gh.lazySingleton<_i628.ValidateDownloadedFileUseCase>(
      () =>
          _i628.ValidateDownloadedFileUseCase(gh<_i373.DownloadsRepository>()),
    );
    gh.singleton<_i594.CheckSurahDownloadedUseCase>(
      () => _i594.CheckSurahDownloadedUseCase(gh<_i373.DownloadsRepository>()),
    );
    gh.singleton<_i823.ClearAllDownloadsUseCase>(
      () => _i823.ClearAllDownloadsUseCase(gh<_i373.DownloadsRepository>()),
    );
    gh.singleton<_i893.DeleteDownloadUseCase>(
      () => _i893.DeleteDownloadUseCase(gh<_i373.DownloadsRepository>()),
    );
    gh.factory<_i807.CancelDownloadUseCase>(
      () => _i807.CancelDownloadUseCase(gh<_i373.DownloadsRepository>()),
    );
    gh.factory<_i862.DeleteReciterDownloadsUseCase>(
      () =>
          _i862.DeleteReciterDownloadsUseCase(gh<_i373.DownloadsRepository>()),
    );
    gh.lazySingleton<_i218.SingleDownloadRepository>(
      () => downloadsModule.singleDownloadRepository(
        gh<_i373.DownloadsRepository>(),
      ),
    );
    gh.lazySingleton<_i549.BatchDownloadRepository>(
      () => downloadsModule.batchDownloadRepository(
        gh<_i373.DownloadsRepository>(),
      ),
    );
    gh.lazySingleton<_i56.DownloadQueryRepository>(
      () => downloadsModule.downloadQueryRepository(
        gh<_i373.DownloadsRepository>(),
      ),
    );
    gh.factory<_i702.CheckAudioPlayabilityUseCase>(
      () => _i702.CheckAudioPlayabilityUseCase(
        gh<_i99.NetworkInfo>(),
        gh<_i373.DownloadsRepository>(),
      ),
    );
    gh.factory<_i817.CancelDownloadsForReciterUseCase>(
      () => _i817.CancelDownloadsForReciterUseCase(
        gh<_i373.DownloadsRepository>(),
        gh<_i1039.RecitersRepository>(),
      ),
    );
    gh.factory<_i605.GetDownloadsByReciterUseCase>(
      () => _i605.GetDownloadsByReciterUseCase(
        gh<_i373.DownloadsRepository>(),
        gh<_i1039.RecitersRepository>(),
      ),
    );
    gh.factory<_i274.GetValidCompletedDownloadsUseCase>(
      () => _i274.GetValidCompletedDownloadsUseCase(
        gh<_i373.DownloadsRepository>(),
        gh<_i1039.RecitersRepository>(),
      ),
    );
    gh.factory<_i387.SurahBloc>(
      () => _i387.SurahBloc(
        gh<_i792.GetSurahsForReciterUseCase>(),
        gh<_i889.UpdateSurahDownloadStatusUseCase>(),
        gh<_i815.UpdateSurahDownloadProgressUseCase>(),
        gh<_i527.CheckSurahDownloadStatusUseCase>(),
        gh<_i162.RefreshSurahStatusUseCase>(),
      ),
    );
    gh.singleton<_i231.DownloadSurahUseCase>(
      () => _i231.DownloadSurahUseCase(gh<_i218.SingleDownloadRepository>()),
    );
    gh.factory<_i767.ObserveDownloadProgressUseCase>(
      () => _i767.ObserveDownloadProgressUseCase(
        gh<_i218.SingleDownloadRepository>(),
      ),
    );
    gh.factory<_i446.ObserveReciterDownloadsUseCase>(
      () => _i446.ObserveReciterDownloadsUseCase(
        gh<_i218.SingleDownloadRepository>(),
      ),
    );
    gh.singleton<_i645.DownloadAllSurahsUseCase>(
      () => _i645.DownloadAllSurahsUseCase(gh<_i549.BatchDownloadRepository>()),
    );
    gh.factory<_i405.ConvertAudioEntitiesToSurahsUseCase>(
      () => _i405.ConvertAudioEntitiesToSurahsUseCase(
        gh<_i697.SurahRepository>(),
        gh<_i373.DownloadsRepository>(),
        gh<_i1039.RecitersRepository>(),
      ),
    );
    await gh.singletonAsync<_i563.AudioPlayerHandler>(
      () => externalDependenciesModule.audioPlayerHandler(
        gh<List<_i87.MediaItem>>(),
        gh<_i145.AnalyticsService>(),
        gh<_i460.SharedPreferencesAsync>(),
        gh<_i1039.RecitersRepository>(),
        gh<_i373.DownloadsRepository>(),
      ),
      preResolve: true,
    );
    gh.factory<_i184.ReciterDetailsBloc>(
      () => _i184.ReciterDetailsBloc(
        gh<_i563.AudioPlayerHandler>(),
        gh<_i405.ConvertAudioEntitiesToSurahsUseCase>(),
        gh<_i863.RefreshSurahDownloadStatusUseCase>(),
        gh<_i274.GetValidCompletedDownloadsUseCase>(),
      ),
    );
    gh.lazySingleton<_i868.PlayAllDownloadsUseCase>(
      () => _i868.PlayAllDownloadsUseCase(
        gh<_i373.DownloadsRepository>(),
        gh<_i563.AudioPlayerHandler>(),
      ),
    );
    gh.lazySingleton<_i912.PlayDownloadUseCase>(
      () => _i912.PlayDownloadUseCase(
        gh<_i373.DownloadsRepository>(),
        gh<_i563.AudioPlayerHandler>(),
      ),
    );
    gh.lazySingleton<_i489.AudioPlayerRepository>(
      () => _i198.AudioPlayerRepositoryImpl(
        gh<_i563.AudioPlayerHandler>(),
        gh<_i641.AudioPositionService>(),
      ),
    );
    gh.factory<_i510.ReciterDownloadBloc>(
      () => _i510.ReciterDownloadBloc(
        gh<_i645.DownloadAllSurahsUseCase>(),
        gh<_i817.CancelDownloadsForReciterUseCase>(),
        gh<_i446.ObserveReciterDownloadsUseCase>(),
      ),
    );
    gh.factory<_i28.PlayAudioUseCase>(
      () => _i28.PlayAudioUseCase(gh<_i489.AudioPlayerRepository>()),
    );
    gh.factory<_i28.PauseAudioUseCase>(
      () => _i28.PauseAudioUseCase(gh<_i489.AudioPlayerRepository>()),
    );
    gh.factory<_i28.StopAudioUseCase>(
      () => _i28.StopAudioUseCase(gh<_i489.AudioPlayerRepository>()),
    );
    gh.factory<_i28.SeekToUseCase>(
      () => _i28.SeekToUseCase(gh<_i489.AudioPlayerRepository>()),
    );
    gh.factory<_i28.SkipToNextUseCase>(
      () => _i28.SkipToNextUseCase(gh<_i489.AudioPlayerRepository>()),
    );
    gh.factory<_i28.SkipToPreviousUseCase>(
      () => _i28.SkipToPreviousUseCase(gh<_i489.AudioPlayerRepository>()),
    );
    gh.factory<_i28.SetVolumeUseCase>(
      () => _i28.SetVolumeUseCase(gh<_i489.AudioPlayerRepository>()),
    );
    gh.factory<_i28.SetPlaybackSpeedUseCase>(
      () => _i28.SetPlaybackSpeedUseCase(gh<_i489.AudioPlayerRepository>()),
    );
    gh.factory<_i28.SetRepeatModeUseCase>(
      () => _i28.SetRepeatModeUseCase(gh<_i489.AudioPlayerRepository>()),
    );
    gh.factory<_i28.SetShuffleModeUseCase>(
      () => _i28.SetShuffleModeUseCase(gh<_i489.AudioPlayerRepository>()),
    );
    gh.factory<_i28.SkipToQueueItemUseCase>(
      () => _i28.SkipToQueueItemUseCase(gh<_i489.AudioPlayerRepository>()),
    );
    gh.factory<_i28.PlayFromQueueUseCase>(
      () => _i28.PlayFromQueueUseCase(gh<_i489.AudioPlayerRepository>()),
    );
    gh.factory<_i28.UpdateQueueUseCase>(
      () => _i28.UpdateQueueUseCase(gh<_i489.AudioPlayerRepository>()),
    );
    gh.factory<_i28.MoveQueueItemUseCase>(
      () => _i28.MoveQueueItemUseCase(gh<_i489.AudioPlayerRepository>()),
    );
    gh.factory<_i28.AddQueueItemUseCase>(
      () => _i28.AddQueueItemUseCase(gh<_i489.AudioPlayerRepository>()),
    );
    gh.factory<_i28.RemoveQueueItemUseCase>(
      () => _i28.RemoveQueueItemUseCase(gh<_i489.AudioPlayerRepository>()),
    );
    gh.factory<_i28.LoadAudioPlayerDataUseCase>(
      () => _i28.LoadAudioPlayerDataUseCase(gh<_i489.AudioPlayerRepository>()),
    );
    gh.factory<_i902.GetAudioStreamsUseCase>(
      () => _i902.GetAudioStreamsUseCase(gh<_i489.AudioPlayerRepository>()),
    );
    gh.factory<_i354.DownloadsBloc>(
      () => _i354.DownloadsBloc(
        getDownloadsByReciter: gh<_i605.GetDownloadsByReciterUseCase>(),
        downloadSurah: gh<_i231.DownloadSurahUseCase>(),
        deleteDownload: gh<_i893.DeleteDownloadUseCase>(),
        deleteReciterDownloads: gh<_i862.DeleteReciterDownloadsUseCase>(),
        clearAllDownloads: gh<_i823.ClearAllDownloadsUseCase>(),
        getTotalDownloadsSize: gh<_i589.GetTotalDownloadsSizeUseCase>(),
        checkSurahDownloaded: gh<_i594.CheckSurahDownloadedUseCase>(),
        validateDownloadedFile: gh<_i628.ValidateDownloadedFileUseCase>(),
        getValidCompletedDownloads:
            gh<_i274.GetValidCompletedDownloadsUseCase>(),
        checkDownloadAccess: gh<_i105.CheckDownloadAccessUseCase>(),
        playDownload: gh<_i912.PlayDownloadUseCase>(),
        playAllDownloads: gh<_i868.PlayAllDownloadsUseCase>(),
        retryDownload: gh<_i702.RetryDownloadUseCase>(),
        getDownloadItem: gh<_i822.GetDownloadItemUseCase>(),
        cancelDownload: gh<_i807.CancelDownloadUseCase>(),
        observeGlobalDownloadProgress:
            gh<_i323.ObserveGlobalDownloadProgressUseCase>(),
        getDownloadStatus: gh<_i935.GetDownloadStatusUseCase>(),
        removeFromDownloadQueue: gh<_i204.RemoveFromDownloadQueueUseCase>(),
      ),
    );
    gh.factory<_i433.AudioPlayerBloc>(
      () => _i433.AudioPlayerBloc(
        gh<_i902.GetAudioStreamsUseCase>(),
        gh<_i28.PlayAudioUseCase>(),
        gh<_i28.PauseAudioUseCase>(),
        gh<_i28.StopAudioUseCase>(),
        gh<_i28.SeekToUseCase>(),
        gh<_i28.SkipToNextUseCase>(),
        gh<_i28.SkipToPreviousUseCase>(),
        gh<_i28.SetVolumeUseCase>(),
        gh<_i28.SetPlaybackSpeedUseCase>(),
        gh<_i28.SetRepeatModeUseCase>(),
        gh<_i28.SetShuffleModeUseCase>(),
        gh<_i28.SkipToQueueItemUseCase>(),
        gh<_i28.PlayFromQueueUseCase>(),
        gh<_i28.UpdateQueueUseCase>(),
        gh<_i28.AddQueueItemUseCase>(),
        gh<_i28.RemoveQueueItemUseCase>(),
        gh<_i28.MoveQueueItemUseCase>(),
        gh<_i28.LoadAudioPlayerDataUseCase>(),
        gh<_i702.CheckAudioPlayabilityUseCase>(),
        gh<_i718.SettingsCubit>(),
      ),
    );
    return this;
  }
}

class _$ExternalDependenciesModule extends _i133.ExternalDependenciesModule {}

class _$DownloadsModule extends _i443.DownloadsModule {}
