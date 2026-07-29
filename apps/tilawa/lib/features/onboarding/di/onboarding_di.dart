import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:tilawa/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:tilawa/features/onboarding/domain/usecases/check_onboarding_status.dart';
import 'package:tilawa/features/onboarding/domain/usecases/complete_onboarding.dart';
import 'package:tilawa/features/onboarding/presentation/cubit/onboarding_cubit.dart';

/// Manual GetIt registrations for `onboarding`.
class OnboardingDi {
  OnboardingDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<OnboardingRepository>(
      () => OnboardingRepositoryImpl(getIt<SharedPreferencesAsync>()),
    );
    getIt.registerFactoryIfAbsent<CheckOnboardingStatus>(
      () => CheckOnboardingStatus(getIt<OnboardingRepository>()),
    );
    getIt.registerFactoryIfAbsent<CompleteOnboarding>(
      () => CompleteOnboarding(getIt<OnboardingRepository>()),
    );
    getIt.registerFactoryIfAbsent<OnboardingCubit>(
      () => OnboardingCubit(getIt<CompleteOnboarding>()),
    );
  }
}
