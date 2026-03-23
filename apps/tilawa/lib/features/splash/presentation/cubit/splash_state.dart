part of 'splash_cubit.dart';

/// States for the [SplashCubit].
///
/// Represents the possible navigation destinations from the splash screen.
sealed class SplashState {
  const SplashState();
}

/// Initial state while splash screen is loading.
class SplashInitial extends SplashState {
  const SplashInitial();
}

/// Navigate to home screen (user is authenticated and onboarding completed).
class SplashNavigateToHome extends SplashState {
  const SplashNavigateToHome();
}

/// Navigate to login screen (user is not authenticated).
class SplashNavigateToLogin extends SplashState {
  const SplashNavigateToLogin();
}

/// Navigate to onboarding screen (first launch).
class SplashNavigateToOnboarding extends SplashState {
  const SplashNavigateToOnboarding();
}

/// Navigate to a deep link from a notification launch.
class SplashNavigateToNotification extends SplashState {
  const SplashNavigateToNotification(this.location);
  final String location;
}
