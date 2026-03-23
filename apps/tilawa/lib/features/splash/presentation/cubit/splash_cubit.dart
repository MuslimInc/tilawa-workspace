import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../main.dart';
import '../../../notifications/presentation/services/fcm_notification_handler_service.dart';
import '../../domain/usecases/get_splash_next_route_use_case.dart';

part 'splash_state.dart';

/// Cubit responsible for splash screen logic and initial navigation.
///
/// Determines the next destination based on:
/// - Notification launch (highest priority)
/// - Onboarding completion status
/// - User authentication status
@injectable
class SplashCubit extends Cubit<SplashState> {
  SplashCubit(this._getSplashNextRoute) : super(const SplashInitial());

  final GetSplashNextRouteUseCase _getSplashNextRoute;

  Future<void> init() async {
    logger.d('[FCM Issue] SplashCubit.init() started');
    try {
      final SplashRouteResult result = await _getSplashNextRoute();
      logger.d('[FCM Issue] SplashCubit destination: ${result.destination}');
      logger.d(
        '[FCM Issue] SplashCubit notificationData: ${result.notificationData}',
      );

      // Skip the artificial splash delay for notification launches so the
      // cold-start deep link can be shown immediately.
      if (result.destination != SplashDestination.notificationLaunch) {
        await Future.delayed(const Duration(seconds: 2));
      }

      String? location;
      if (result.destination == SplashDestination.notificationLaunch &&
          result.notificationData != null) {
        location = FCMNotificationHandlerService.resolveLocation(
          result.notificationData!,
        );
      }
      logger.d('[FCM Issue] SplashCubit resolved location: $location');

      final state = switch (result.destination) {
        SplashDestination.home => const SplashNavigateToHome(),
        SplashDestination.login => const SplashNavigateToLogin(),
        SplashDestination.onboarding => const SplashNavigateToOnboarding(),
        SplashDestination.notificationLaunch when location != null =>
          SplashNavigateToNotification(location),
        SplashDestination.notificationLaunch => const SplashNavigateToHome(),
      };
      logger.d('[FCM Issue] SplashCubit emitting state: $state');
      if (isClosed) {
        return;
      }
      emit(state);
      logger.d('[FCM Issue] SplashCubit emit done, isClosed=$isClosed');
    } catch (e, stackTrace) {
      // Fallback to home on any unexpected error to avoid a frozen splash
      logger.e(
        '[FCM Issue] SplashCubit ERROR: $e',
        error: e,
        stackTrace: stackTrace,
      );
      emit(const SplashNavigateToHome());
    }
  }
}
