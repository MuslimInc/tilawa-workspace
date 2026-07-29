import 'package:get_it/get_it.dart';
import 'package:tilawa/core/bootstrap/app_startup_readiness.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/auth/domain/usecases/await_auth_restoration_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/get_persisted_authenticated_user_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/prepare_google_sign_in_use_case.dart';
import 'package:tilawa/features/onboarding/domain/usecases/check_onboarding_status.dart';
import 'package:tilawa/features/splash/data/repositories/startup_notification_repository_impl.dart';
import 'package:tilawa/features/splash/domain/repositories/startup_notification_repository.dart';
import 'package:tilawa/features/splash/domain/usecases/get_splash_next_route_use_case.dart';
import 'package:tilawa/features/splash/presentation/bloc/splash_bloc.dart';

/// Manual GetIt registrations for `splash`.
class SplashDi {
  SplashDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<StartupNotificationRepository>(
      StartupNotificationRepositoryImpl.new,
    );
    getIt.registerFactoryIfAbsent<GetSplashNextRouteUseCase>(
      () => GetSplashNextRouteUseCase(
        getIt<GetCurrentUserUseCase>(),
        getIt<CheckOnboardingStatus>(),
        getIt<StartupNotificationRepository>(),
        getIt<AwaitAuthRestorationUseCase>(),
        getIt<GetPersistedAuthenticatedUserUseCase>(),
      ),
    );
    getIt.registerFactoryIfAbsent<SplashBloc>(
      () => SplashBloc(
        getIt<GetSplashNextRouteUseCase>(),
        getIt<PrepareGoogleSignInUseCase>(),
        getIt<AppStartupReadiness>(),
      ),
    );
  }
}
