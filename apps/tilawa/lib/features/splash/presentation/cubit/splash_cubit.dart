import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

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
    try {
      final SplashRouteResult result = await _getSplashNextRoute();

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
    } catch (_) {
      // Fallback to home on any unexpected error to avoid a frozen splash
      emit(const SplashNavigateToHome());
    }
  }
}
