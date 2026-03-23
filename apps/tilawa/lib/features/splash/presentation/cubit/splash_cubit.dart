import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

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
  SplashCubit(this._getSplashNextRoute, this._dispatcher)
    : super(const SplashInitial());

  final GetSplashNextRouteUseCase _getSplashNextRoute;
  final INotificationDispatcher _dispatcher;

  Future<void> init() async {
    // Artificial delay to display branding
    await Future.delayed(const Duration(seconds: 2));

    try {
      final SplashDestination destination = await _getSplashNextRoute();

      final location = destination == SplashDestination.notificationLaunch
          ? await _resolveNotificationRoute()
          : null;

      emit(switch (destination) {
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

  Future<String?> _resolveNotificationRoute() async {
    final details = await _dispatcher.getNotificationAppLaunchDetails();
    final payload = details?.notificationResponse?.payload;
    if (payload == null) return null;

    try {
      final data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
      return FCMNotificationHandlerService.resolveLocation(data);
    } catch (_) {
      return null;
    }
  }
}
