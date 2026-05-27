import 'package:injectable/injectable.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/usecases/get_current_user_use_case.dart';
import '../../../onboarding/domain/usecases/check_onboarding_status.dart';
import '../repositories/startup_notification_repository.dart';

enum SplashDestination { home, login, onboarding, notificationLaunch }

class SplashRouteResult {
  const SplashRouteResult(this.destination, {this.notificationData});
  final SplashDestination destination;
  final Map<String, dynamic>? notificationData;
}

@injectable
class GetSplashNextRouteUseCase {
  GetSplashNextRouteUseCase(
    this._getCurrentUserUseCase,
    this._checkOnboardingStatus,
    this._startupNotificationRepository,
  );

  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final CheckOnboardingStatus _checkOnboardingStatus;
  final StartupNotificationRepository _startupNotificationRepository;

  Future<SplashRouteResult> call() async {
    final Map<String, dynamic>? notificationData =
        _startupNotificationRepository.consumePendingNotification();
    if (notificationData != null) {
      return SplashRouteResult(
        SplashDestination.notificationLaunch,
        notificationData: notificationData.isEmpty ? null : notificationData,
      );
    }

    final bool isOnboardingCompleted = await _checkOnboardingStatus();
    if (!isOnboardingCompleted) {
      return const SplashRouteResult(SplashDestination.onboarding);
    }

    final UserEntity? user = _getCurrentUserUseCase();
    if (user != null) {
      return const SplashRouteResult(SplashDestination.home);
    }

    return const SplashRouteResult(SplashDestination.login);
  }
}
