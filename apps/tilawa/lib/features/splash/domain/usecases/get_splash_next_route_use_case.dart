import 'dart:convert';

import 'package:injectable/injectable.dart';
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
  );

  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final CheckOnboardingStatus _checkOnboardingStatus;

  Future<SplashRouteResult> call() async {
    final localNotificationResponse =
        AppRouter.pendingLocalNotificationResponse;
    if (localNotificationResponse != null) {
      AppRouter.pendingLocalNotificationResponse = null;

      // Record the ID so the resume handler in TilawaApp does not
      // re-process this same launch notification on the first resume.
      AppRouter.lastProcessedNotificationId = localNotificationResponse.id;

      final payload = localNotificationResponse.payload;
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
    if (pendingFcm != null) {
      AppRouter.pendingFcmMessage = null;
      return SplashRouteResult(
        SplashDestination.notificationLaunch,
        notificationData: pendingFcm.data,
      );
    }

    final bool isOnboardingCompleted = await _checkOnboardingStatus();
    if (!isOnboardingCompleted) {
      return SplashRouteResult(SplashDestination.onboarding);
    }

    final UserEntity? user = _getCurrentUserUseCase();

    if (user != null) {
      return SplashRouteResult(SplashDestination.home);
    }

    return SplashRouteResult(SplashDestination.login);
  }
}
