import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

import '../../../../main.dart';
import '../../../../router/app_router.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/usecases/get_current_user_use_case.dart';
import '../../../onboarding/domain/usecases/check_onboarding_status.dart';

enum SplashDestination { home, login, onboarding, notificationLaunch }

/// Result of determining the splash next route.
/// When [destination] is [SplashDestination.notificationLaunch],
/// [notificationData] contains the payload to resolve the deep link.
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
    this._dispatcher,
  );

  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final CheckOnboardingStatus _checkOnboardingStatus;
  final INotificationDispatcher _dispatcher;

  Future<SplashRouteResult> call() async {
    logger.d('[FCM Issue] GetSplashNextRouteUseCase.call() started');

    // Check if app was launched from a local notification (athkar, downloads)
    final details = await _dispatcher.getNotificationAppLaunchDetails();
    logger.d(
      '[FCM Issue] Local notification: didLaunch=${details?.didNotificationLaunchApp}, payload=${details?.notificationResponse?.payload}',
    );
    if (details != null &&
        details.didNotificationLaunchApp &&
        details.notificationResponse != null) {
      final payload = details.notificationResponse!.payload;
      logger.d('[FCM Issue] => notificationLaunch (local), payload=$payload');
      Map<String, dynamic>? data;
      if (payload != null) {
        try {
          data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
        } catch (_) {}
      }
      return SplashRouteResult(
        SplashDestination.notificationLaunch,
        notificationData: data,
      );
    }

    // Check if app was launched from an FCM push notification.
    // The initial message was already consumed in main.dart and stored in
    // AppRouter.pendingFcmMessage (getInitialMessage() can only be called once).
    final pendingFcm = AppRouter.pendingFcmMessage;
    logger.d('[FCM Issue] FCM pendingFcmMessage data: ${pendingFcm?.data}');
    if (pendingFcm != null) {
      // Clear so it's not re-processed
      AppRouter.pendingFcmMessage = null;
      logger.d('[FCM Issue] => notificationLaunch (FCM)');
      return SplashRouteResult(
        SplashDestination.notificationLaunch,
        notificationData: pendingFcm.data,
      );
    }

    final bool isOnboardingCompleted = await _checkOnboardingStatus();
    logger.d('[FCM Issue] isOnboardingCompleted: $isOnboardingCompleted');
    if (!isOnboardingCompleted) {
      return SplashRouteResult(SplashDestination.onboarding);
    }

    final UserEntity? user = _getCurrentUserUseCase();
    logger.d('[FCM Issue] currentUser: $user');

    if (user != null) {
      return SplashRouteResult(SplashDestination.home);
    }

    return SplashRouteResult(SplashDestination.login);
  }
}
