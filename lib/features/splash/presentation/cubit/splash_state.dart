part of 'splash_cubit.dart';

sealed class SplashState {
  const SplashState();
}

class SplashInitial extends SplashState {
  const SplashInitial();
}

class SplashNavigateToHome extends SplashState {
  const SplashNavigateToHome();
}

class SplashNavigateToLogin extends SplashState {
  const SplashNavigateToLogin();
}

class SplashNavigateToOnboarding extends SplashState {
  const SplashNavigateToOnboarding();
}
