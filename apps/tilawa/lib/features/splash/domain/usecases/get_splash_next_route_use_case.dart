import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/usecases/await_auth_restoration_use_case.dart';
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
    this._awaitAuthRestoration,
  );

  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final CheckOnboardingStatus _checkOnboardingStatus;
  final StartupNotificationRepository _startupNotificationRepository;
  final AwaitAuthRestorationUseCase _awaitAuthRestoration;

  Future<SplashRouteResult> call() async {
    logger.d('[DebugNotificationAuthFlow] startup route resolution started');

    final Map<String, dynamic>? notificationData =
        _startupNotificationRepository.consumePendingNotification();
    logger.d(
      '[DebugNotificationAuthFlow] pending notification route '
      '${notificationData == null ? 'not found' : 'found'}',
    );

    final bool isOnboardingCompleted = await _checkOnboardingStatus();
    if (!isOnboardingCompleted) {
      return const SplashRouteResult(SplashDestination.onboarding);
    }

    logger.d('[DebugNotificationAuthFlow] auth restoration started');
    await _awaitAuthRestoration();
    final UserEntity? user = _getCurrentUserUseCase();

    if (user != null) {
      if (notificationData != null) {
        logger.d(
          '[DebugNotificationAuthFlow] startup route notification '
          'userId=${user.id}',
        );
        return SplashRouteResult(
          SplashDestination.notificationLaunch,
          notificationData: notificationData.isEmpty ? null : notificationData,
        );
      }
      logger.d(
        '[DebugNotificationAuthFlow] startup route home userId=${user.id}',
      );
      return const SplashRouteResult(SplashDestination.home);
    }

    logger.d(
      '[DebugNotificationAuthFlow] startup route login (no restored user) '
      'pendingNotificationDiscarded=${notificationData != null}',
    );
    return const SplashRouteResult(SplashDestination.login);
  }
}
