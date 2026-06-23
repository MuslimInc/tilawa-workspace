/// Result of a pre-flight check before launching Google sign-in UI.
sealed class GoogleSignInLaunchReadiness {
  const GoogleSignInLaunchReadiness();

  const factory GoogleSignInLaunchReadiness.ready() = GoogleSignInLaunchReady;

  const factory GoogleSignInLaunchReadiness.uiUnavailable() =
      GoogleSignInLaunchUiUnavailable;

  const factory GoogleSignInLaunchReadiness.platformError({
    required String code,
    String? message,
  }) = GoogleSignInLaunchPlatformError;
}

final class GoogleSignInLaunchReady extends GoogleSignInLaunchReadiness {
  const GoogleSignInLaunchReady();
}

final class GoogleSignInLaunchUiUnavailable
    extends GoogleSignInLaunchReadiness {
  const GoogleSignInLaunchUiUnavailable();
}

final class GoogleSignInLaunchPlatformError
    extends GoogleSignInLaunchReadiness {
  const GoogleSignInLaunchPlatformError({
    required this.code,
    this.message,
  });

  final String code;
  final String? message;
}
