import '../entities/google_sign_in_launch_readiness.dart';

/// Platform pre-flight and UI-settle hooks for interactive Google sign-in.
abstract class GoogleSignInLaunchGateway {
  Future<GoogleSignInLaunchReadiness> checkReadiness();

  Future<void> runAfterUiSettled(Future<void> Function() action);
}
