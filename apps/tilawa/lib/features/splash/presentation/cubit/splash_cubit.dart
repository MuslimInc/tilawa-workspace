import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/get_splash_next_route_use_case.dart';

part 'splash_state.dart';

/// Cubit responsible for splash screen logic and initial navigation.
///
/// Determines the next destination based on:
/// - Onboarding completion status
/// - User authentication status
@injectable
class SplashCubit extends Cubit<SplashState> {
  SplashCubit(this._getSplashNextRoute) : super(const SplashInitial());

  final GetSplashNextRouteUseCase _getSplashNextRoute;

  Future<void> init() async {
    // Artificial delay to display branding
    await Future.delayed(const Duration(seconds: 2));

    try {
      final SplashDestination destination = await _getSplashNextRoute();

      switch (destination) {
        case SplashDestination.home:
          emit(const SplashNavigateToHome());
        case SplashDestination.login:
          emit(const SplashNavigateToLogin());
        case SplashDestination.onboarding:
          emit(const SplashNavigateToOnboarding());
        case SplashDestination.notificationLaunch:
          // Let the notification service handle navigation, but fall back to
          // home after a timeout to avoid leaving the user stuck on splash.
          Future.delayed(const Duration(seconds: 5), () {
            if (!isClosed && state is SplashInitial) {
              emit(const SplashNavigateToHome());
            }
          });
      }
    } catch (_) {
      // Fallback to home on any unexpected error to avoid a frozen splash
      emit(const SplashNavigateToHome());
    }
  }
}
