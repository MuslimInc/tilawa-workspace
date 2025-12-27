import 'package:injectable/injectable.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/usecases/get_current_user_use_case.dart';
import '../../../onboarding/domain/usecases/check_onboarding_status.dart';

enum SplashDestination { home, login, onboarding }

@injectable
class GetSplashNextRouteUseCase {
  GetSplashNextRouteUseCase(
    this._getCurrentUserUseCase,
    this._checkOnboardingStatus,
  );

  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final CheckOnboardingStatus _checkOnboardingStatus;

  Future<SplashDestination> call() async {
    final bool isOnboardingCompleted = await _checkOnboardingStatus();
    if (!isOnboardingCompleted) {
      return SplashDestination.onboarding;
    }

    // Check user for future logic (e.g. specialized greeting or analytics)
    final UserEntity? user = _getCurrentUserUseCase();

    if (user != null) {
      // User is logged in
      return SplashDestination.home;
    }

    return SplashDestination.login;
  }
}
