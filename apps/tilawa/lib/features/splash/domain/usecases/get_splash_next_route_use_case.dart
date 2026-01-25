import 'package:injectable/injectable.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/usecases/get_current_user_use_case.dart';
import '../../../onboarding/domain/usecases/check_onboarding_status.dart';

enum SplashDestination { home, login, onboarding, notificationLaunch }

@injectable
class GetSplashNextRouteUseCase {
  GetSplashNextRouteUseCase(
    this._getCurrentUserUseCase,
    this._checkOnboardingStatus,
    this._dispatcher,
  );

  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final CheckOnboardingStatus _checkOnboardingStatus;
  final INotificationDispatcher _dispatcher;

  Future<SplashDestination> call() async {
    // Check if app was launched from notification first
    final details = await _dispatcher.getNotificationAppLaunchDetails();
    if (details != null &&
        details.didNotificationLaunchApp &&
        details.notificationResponse != null) {
      return SplashDestination.notificationLaunch;
    }

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
