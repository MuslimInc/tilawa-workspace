import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';

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
  // Temporary preview delay for checking the Flutter splash.
  // Set to Duration.zero to disable.
  static const Duration flutterSplashPreviewDelay = Duration.zero;

  SplashCubit(this._getSplashNextRoute) : super(const SplashInitial());

  final GetSplashNextRouteUseCase _getSplashNextRoute;

  Future<void> init() async {
    try {
      final Future<SplashRouteResult> routeFuture = _getSplashNextRoute();
      if (flutterSplashPreviewDelay > Duration.zero) {
        await Future<void>.delayed(flutterSplashPreviewDelay);
      }
      final SplashRouteResult result = await routeFuture;

      String? location;
      if (result.destination == SplashDestination.notificationLaunch &&
          result.notificationData != null) {
        location = FCMNotificationHandlerService.resolveLocation(
          result.notificationData!,
        );
      }

      if (isClosed) return;

      emit(switch (result.destination) {
        SplashDestination.home => const SplashNavigateToHome(),
        SplashDestination.login => const SplashNavigateToLogin(),
        SplashDestination.onboarding => const SplashNavigateToOnboarding(),
        SplashDestination.notificationLaunch when location != null =>
          SplashNavigateToNotification(location),
        SplashDestination.notificationLaunch => const SplashNavigateToHome(),
      });
    } catch (e, stackTrace) {
      logger.e(
        'Splash init failed, falling back to home',
        error: e,
        stackTrace: stackTrace,
      );
      emit(const SplashNavigateToHome());
    }
  }
}
