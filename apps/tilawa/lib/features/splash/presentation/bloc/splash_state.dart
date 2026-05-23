import 'package:equatable/equatable.dart';

/// States for [SplashBloc].
sealed class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

/// Splash is resolving readiness and the next route.
final class SplashLoading extends SplashState {
  const SplashLoading();
}

/// Navigate to home (authenticated, onboarding done).
final class SplashNavigateToHome extends SplashState {
  const SplashNavigateToHome({this.timedOut = false});
  final bool timedOut;
  @override
  List<Object?> get props => [timedOut];
}

/// Navigate to login.
final class SplashNavigateToLogin extends SplashState {
  const SplashNavigateToLogin();
}

/// Navigate to onboarding (first launch).
final class SplashNavigateToOnboarding extends SplashState {
  const SplashNavigateToOnboarding();
}

/// Navigate to a notification cold-start deep link.
final class SplashNavigateToNotification extends SplashState {
  const SplashNavigateToNotification(this.location, {this.extra});
  final String location;
  final Object? extra;
  @override
  List<Object?> get props => [location, extra];
}

/// Unrecoverable splash failure; UI may retry or fall back.
final class SplashFailure extends SplashState {
  const SplashFailure();
}
