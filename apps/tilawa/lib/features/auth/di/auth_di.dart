import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/core/domain/server_action_guard.dart';
import 'package:tilawa/core/services/device_token_service.dart';
import 'package:tilawa/features/auth/application/account_deletion_flow_tracker.dart';
import 'package:tilawa/features/auth/data/auth_service.dart';
import 'package:tilawa/features/auth/data/datasources/account_deletion_remote_data_source.dart';
import 'package:tilawa/features/auth/data/datasources/account_deletion_remote_data_source_impl.dart';
import 'package:tilawa/features/auth/data/datasources/active_device_remote_data_source.dart';
import 'package:tilawa/features/auth/data/datasources/active_device_remote_data_source_impl.dart';
import 'package:tilawa/features/auth/data/datasources/firebase_apple_auth_gateway.dart';
import 'package:tilawa/features/auth/data/datasources/firebase_email_password_auth_gateway.dart';
import 'package:tilawa/features/auth/data/datasources/google_sign_in_prepare_data_source.dart';
import 'package:tilawa/features/auth/data/datasources/profile_avatar_storage.dart';
import 'package:tilawa/features/auth/data/providers/google_auth_provider_impl.dart';
import 'package:tilawa/features/auth/data/repositories/account_deletion_repository_impl.dart';
import 'package:tilawa/features/auth/data/repositories/active_device_repository_impl.dart';
import 'package:tilawa/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tilawa/features/auth/data/repositories/firebase_device_registry_repository.dart';
import 'package:tilawa/features/auth/data/repositories/firestore_session_validity_repository.dart';
import 'package:tilawa/features/auth/data/repositories/user_repository_impl.dart';
import 'package:tilawa/features/auth/data/services/android_sign_in_platform_policy.dart';
import 'package:tilawa/features/auth/data/services/device_identity_service.dart';
import 'package:tilawa/features/auth/data/services/google_sign_in_session_tracker.dart';
import 'package:tilawa/features/auth/data/services/platform_device_info_service.dart';
import 'package:tilawa/features/auth/data/services/token_sync_cache_impl.dart';
import 'package:tilawa/features/auth/device_registry_feature_flags.dart';
import 'package:tilawa/features/auth/domain/gateways/apple_auth_gateway.dart';
import 'package:tilawa/features/auth/domain/gateways/email_password_auth_gateway.dart';
import 'package:tilawa/features/auth/domain/gateways/google_sign_in_launch_gateway.dart';
import 'package:tilawa/features/auth/domain/providers/auth_provider_interface.dart';
import 'package:tilawa/features/auth/domain/repositories/account_deletion_repository.dart';
import 'package:tilawa/features/auth/domain/repositories/active_device_repository.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/repositories/device_registry_repository.dart';
import 'package:tilawa/features/auth/domain/repositories/session_validity_repository.dart';
import 'package:tilawa/features/auth/domain/repositories/user_repository.dart';
import 'package:tilawa/features/auth/domain/services/callable_session_payload_builder.dart';
import 'package:tilawa/features/auth/domain/services/device_info_service.dart';
import 'package:tilawa/features/auth/domain/services/device_revoked_notifier.dart';
import 'package:tilawa/features/auth/domain/services/google_sign_in_launch_readiness_store.dart';
import 'package:tilawa/features/auth/domain/services/session_epoch_provider.dart';
import 'package:tilawa/features/auth/domain/services/session_revoked_notifier.dart';
import 'package:tilawa/features/auth/domain/services/token_sync_cache.dart';
import 'package:tilawa/features/auth/domain/usecases/await_auth_restoration_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/check_session_validity_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/delete_account.dart';
import 'package:tilawa/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/get_persisted_authenticated_user_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/prepare_google_sign_in_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/prewarm_google_sign_in_launch_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/register_active_device_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/register_with_email_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/resolve_authenticated_user_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/resolve_google_sign_in_launch_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/send_password_reset_email_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_in_with_apple_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_in_with_email_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_in_with_google_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_out.dart';
import 'package:tilawa/features/auth/domain/usecases/sync_device_token_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sync_user_language_preference_use_case.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/auth/presentation/cubit/email_auth_form_cubit.dart';
import 'package:tilawa/features/auth/presentation/cubit/email_registration_cubit.dart';
import 'package:tilawa/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:tilawa/features/auth/presentation/cubit/login_google_sign_in_cubit.dart';
import 'package:tilawa/features/auth/presentation/cubit/manage_devices_cubit.dart';
import 'package:tilawa/features/auth/presentation/cubit/session_validity_cubit.dart';
import 'package:tilawa/features/auth/presentation/cubit/session_verification_cubit.dart';
import 'package:tilawa/features/auth/presentation/services/google_sign_in_interactive_launcher.dart';
import 'package:tilawa/features/localization/domain/usecases/get_current_language_use_case.dart';
import 'package:tilawa/features/premium/domain/repositories/premium_repository.dart';
import 'package:tilawa_core/services/interfaces/app_info_service.dart';

/// Manual GetIt registrations for `auth`.
class AuthDi {
  AuthDi._();

  static void register(GetIt getIt) {
    getIt.registerFactoryIfAbsent<EmailAuthFormCubit>(
      EmailAuthFormCubit.new,
    );
    getIt.registerLazySingletonIfAbsent<AccountDeletionFlowTracker>(
      AccountDeletionFlowTracker.new,
    );
    getIt.registerLazySingletonIfAbsent<GoogleSignInSessionTracker>(
      GoogleSignInSessionTracker.new,
    );
    getIt.registerLazySingletonIfAbsent<DeviceRevokedNotifier>(
      DeviceRevokedNotifier.new,
    );
    getIt.registerLazySingletonIfAbsent<GoogleSignInLaunchReadinessStore>(
      GoogleSignInLaunchReadinessStore.new,
    );
    getIt.registerLazySingletonIfAbsent<SessionRevokedNotifier>(
      SessionRevokedNotifier.new,
    );
    getIt.registerLazySingletonIfAbsent<TokenSyncCache>(
      () => TokenSyncCacheImpl(getIt<SharedPreferencesAsync>()),
    );
    getIt.registerLazySingletonIfAbsent<DeviceIdentityService>(
      () => DeviceIdentityServiceImpl(getIt<SharedPreferencesAsync>()),
    );
    getIt.registerLazySingletonIfAbsent<GetPersistedAuthenticatedUserUseCase>(
      () => GetPersistedAuthenticatedUserUseCase(
        getIt<TokenSyncCache>(),
      ),
    );
    getIt.registerFactoryIfAbsent<ResolveGoogleSignInLaunchUseCase>(
      () => ResolveGoogleSignInLaunchUseCase(
        getIt<GoogleSignInLaunchReadinessStore>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<AppleAuthGateway>(
      () => FirebaseAppleAuthGateway(getIt<FirebaseAuth>()),
    );
    getIt.registerLazySingletonIfAbsent<UserRepository>(
      () => UserRepositoryImpl(
        getIt<FirebaseFirestore>(),
        getIt<FirebaseAuth>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<ActiveDeviceRemoteDataSource>(
      () => ActiveDeviceRemoteDataSourceImpl(getIt<FirebaseFunctions>()),
    );
    getIt.registerLazySingletonIfAbsent<EmailPasswordAuthGateway>(
      () => FirebaseEmailPasswordAuthGateway(getIt<FirebaseAuth>()),
    );
    getIt.registerLazySingletonIfAbsent<AndroidSignInPlatformPolicy>(
      () => AndroidSignInPlatformPolicy(
        deviceInfoPlugin: getIt<DeviceInfoPlugin>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<GoogleSignInPrepareDataSource>(
      () => GoogleSignInPrepareDataSourceImpl(
        getIt<GoogleSignIn>(),
        getIt<AndroidSignInPlatformPolicy>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<AuthProviderInterface>(
      () => GoogleAuthProviderImpl(
        getIt<FirebaseAuth>(),
        getIt<GoogleSignIn>(),
        getIt<AndroidSignInPlatformPolicy>(),
        getIt<GoogleSignInSessionTracker>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<ProfileAvatarStorage>(
      () => ProfileAvatarStorage(getIt<FirebaseStorage>()),
    );
    getIt.registerLazySingletonIfAbsent<AccountDeletionRemoteDataSource>(
      () => AccountDeletionRemoteDataSourceImpl(
        getIt<FirebaseFunctions>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<GoogleSignInLaunchGateway>(
      () => GoogleSignInInteractiveLauncher(
        getIt<GoogleSignIn>(),
        getIt<AndroidSignInPlatformPolicy>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<SyncUserLanguagePreferenceUseCase>(
      () => SyncUserLanguagePreferenceUseCase(getIt<UserRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<DeviceInfoService>(
      () => PlatformDeviceInfoService(
        getIt<DeviceInfoPlugin>(),
        getIt<AppInfoService>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<AuthRepository>(
      () => AuthRepositoryImpl(
        getIt<AuthProviderInterface>(),
        getIt<GoogleSignInPrepareDataSource>(),
        getIt<EmailPasswordAuthGateway>(),
        getIt<AppleAuthGateway>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<AuthService>(
      () => AuthService(auth: getIt<FirebaseAuth>()),
    );
    getIt.registerFactoryIfAbsent<RegisterWithEmailUseCase>(
      () => RegisterWithEmailUseCase(
        getIt<AuthRepository>(),
        getIt<UserRepository>(),
        getIt<EmailPasswordAuthGateway>(),
        getIt<ServerActionGuard>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<SessionValidityRepository>(
      () => FirestoreSessionValidityRepository(
        getIt<FirebaseFirestore>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<ActiveDeviceRepository>(
      () => ActiveDeviceRepositoryImpl(
        getIt<ActiveDeviceRemoteDataSource>(),
        getIt<DeviceIdentityService>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<SessionEpochProvider>(
      () => SessionEpochProviderImpl(getIt<TokenSyncCache>()),
    );
    getIt.registerFactoryIfAbsent<SessionVerificationCubit>(
      () => SessionVerificationCubit(
        getIt<AuthRepository>(),
        hardeningEnabled: getIt<AuthLifecycleHardeningEnabledPredicate>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<GetCurrentUserUseCase>(
      () => GetCurrentUserUseCase(getIt<AuthRepository>()),
    );
    getIt.registerFactoryIfAbsent<CheckSessionValidityUseCase>(
      () => CheckSessionValidityUseCase(
        getIt<SessionValidityRepository>(),
        getIt<TokenSyncCache>(),
      ),
    );
    getIt.registerFactoryIfAbsent<SignInWithAppleUseCase>(
      () => SignInWithAppleUseCase(
        getIt<AuthRepository>(),
        getIt<UserRepository>(),
        getIt<ServerActionGuard>(),
      ),
    );
    getIt.registerFactoryIfAbsent<SignInWithEmailUseCase>(
      () => SignInWithEmailUseCase(
        getIt<AuthRepository>(),
        getIt<UserRepository>(),
        getIt<ServerActionGuard>(),
      ),
    );
    getIt.registerFactoryIfAbsent<SignInWithGoogleUseCase>(
      () => SignInWithGoogleUseCase(
        getIt<AuthRepository>(),
        getIt<UserRepository>(),
        getIt<ServerActionGuard>(),
      ),
    );
    getIt.registerFactoryIfAbsent<SendPasswordResetEmailUseCase>(
      () => SendPasswordResetEmailUseCase(
        getIt<EmailPasswordAuthGateway>(),
        getIt<ServerActionGuard>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<AccountDeletionRepository>(
      () => AccountDeletionRepositoryImpl(
        getIt<AccountDeletionRemoteDataSource>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<DeviceRegistryRepository>(
      () => FirebaseDeviceRegistryRepository(
        getIt<FirebaseFirestore>(),
        getIt<DeviceIdentityService>(),
        getIt<FirebaseFunctions>(),
        getIt<FirebaseAuth>(),
      ),
    );
    getIt.registerFactoryIfAbsent<EmailRegistrationCubit>(
      () => EmailRegistrationCubit(getIt<RegisterWithEmailUseCase>()),
    );
    getIt.registerFactoryIfAbsent<ManageDevicesCubit>(
      () => ManageDevicesCubit(getIt<DeviceRegistryRepository>()),
    );
    getIt.registerFactoryIfAbsent<AwaitAuthRestorationUseCase>(
      () => AwaitAuthRestorationUseCase(getIt<AuthRepository>()),
    );
    getIt.registerFactoryIfAbsent<PrepareGoogleSignInUseCase>(
      () => PrepareGoogleSignInUseCase(getIt<AuthRepository>()),
    );
    getIt.registerFactoryIfAbsent<ForgotPasswordCubit>(
      () => ForgotPasswordCubit(getIt<SendPasswordResetEmailUseCase>()),
    );
    getIt.registerFactoryIfAbsent<RegisterActiveDeviceUseCase>(
      () => RegisterActiveDeviceUseCase(
        getIt<ActiveDeviceRepository>(),
        getIt<DeviceTokenService>(),
        getIt<TokenSyncCache>(),
        getIt<AppInfoService>(),
        getIt<DeviceInfoService>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<CallableSessionPayloadBuilder>(
      () => CallableSessionPayloadBuilder(getIt<SessionEpochProvider>()),
    );
    getIt.registerFactoryIfAbsent<SyncDeviceTokenUseCase>(
      () => SyncDeviceTokenUseCase(
        getIt<RegisterActiveDeviceUseCase>(),
        getIt<SessionRevokedNotifier>(),
        multiDeviceLoginEnabled: getIt<MultiDeviceLoginEnabledPredicate>(),
      ),
    );
    getIt.registerFactoryIfAbsent<ResolveAuthenticatedUserUseCase>(
      () => ResolveAuthenticatedUserUseCase(
        getIt<AuthRepository>(),
        getIt<AwaitAuthRestorationUseCase>(),
      ),
    );
    getIt.registerFactoryIfAbsent<PrewarmGoogleSignInLaunchUseCase>(
      () => PrewarmGoogleSignInLaunchUseCase(
        getIt<PrepareGoogleSignInUseCase>(),
        getIt<GoogleSignInLaunchReadinessStore>(),
      ),
    );
    getIt.registerFactoryIfAbsent<SignOut>(
      () => SignOut(
        getIt<AuthRepository>(),
        getIt<SyncDeviceTokenUseCase>(),
        getIt<PremiumRepository>(),
        getIt<TokenSyncCache>(),
        getIt<ServerActionGuard>(),
      ),
    );
    getIt.registerFactoryIfAbsent<LoginGoogleSignInCubit>(
      () => LoginGoogleSignInCubit(
        getIt<PrewarmGoogleSignInLaunchUseCase>(),
        getIt<ResolveGoogleSignInLaunchUseCase>(),
        getIt<ServerActionGuard>(),
      ),
    );
    getIt.registerFactoryIfAbsent<SessionValidityCubit>(
      () => SessionValidityCubit(
        getIt<AuthRepository>(),
        getIt<CheckSessionValidityUseCase>(),
        getIt<SignOut>(),
        getIt<SessionRevokedNotifier>(),
        getIt<GoogleSignInSessionTracker>(),
        multiDeviceLoginEnabled: getIt<MultiDeviceLoginEnabledPredicate>(),
      ),
    );
    getIt.registerFactoryIfAbsent<DeleteAccount>(
      () => DeleteAccount(
        getIt<AuthRepository>(),
        getIt<AccountDeletionRepository>(),
        getIt<SyncDeviceTokenUseCase>(),
        getIt<PremiumRepository>(),
        getIt<ServerActionGuard>(),
        getIt<ResolveAuthenticatedUserUseCase>(),
      ),
    );
    getIt.registerFactoryIfAbsent<AuthBloc>(
      () => AuthBloc(
        getIt<SignInWithGoogleUseCase>(),
        getIt<SignInWithAppleUseCase>(),
        getIt<SignInWithEmailUseCase>(),
        getIt<RegisterWithEmailUseCase>(),
        getIt<SignOut>(),
        getIt<DeleteAccount>(),
        getIt<GetCurrentUserUseCase>(),
        getIt<SyncDeviceTokenUseCase>(),
        getIt<GetCurrentLanguageUseCase>(),
        getIt<SyncUserLanguagePreferenceUseCase>(),
        getIt<AccountDeletionFlowTracker>(),
        getIt<GoogleSignInSessionTracker>(),
        getIt<AwaitAuthRestorationUseCase>(),
        getIt<GetPersistedAuthenticatedUserUseCase>(),
        multiDeviceLoginEnabled: getIt<MultiDeviceLoginEnabledPredicate>(),
      ),
    );
  }
}
