import 'package:tilawa/core/firebase/app_check_failure.dart';
import 'package:tilawa/core/network/network_error_message.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/auth_error_key.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/auth_bloc.dart';
import '../cubit/login_google_sign_in_cubit.dart';
import 'email_auth_route_guard.dart';

/// User-visible copy for login auth listener side effects.
class LoginAuthBlocTransitionMessages {
  const LoginAuthBlocTransitionMessages({
    required this.authErrorFallback,
    required this.noGoogleAccounts,
    required this.googleSignInCancelled,
    required this.localizeAuthError,
    this.deviceRegistrationFailed = '',
    this.appCheckFailed = '',
    this.serverActionOffline = '',
  });

  final String authErrorFallback;
  final String deviceRegistrationFailed;
  final String appCheckFailed;
  final String serverActionOffline;
  final String noGoogleAccounts;
  final String googleSignInCancelled;
  final String Function(String messageKey) localizeAuthError;
}

/// Navigates away when [state] is already authenticated on login root.
///
/// [LoginAuthBlocListener] only reacts to transitions into authenticated;
/// Firebase may settle auth before the first listener callback runs.
void handleExistingAuthenticatedLoginSession({
  required AuthState state,
  required String routeLocation,
  required void Function(UserEntity user) onNavigateAfterAuth,
}) {
  if (!isLoginSurfaceHandlingAuthTransitions(routeLocation)) {
    return;
  }
  state.whenOrNull(
    authenticated: (UserEntity user) => onNavigateAfterAuth(user),
  );
}

/// Applies login-screen side effects for a listened [AuthState] transition.
void handleLoginAuthBlocTransition({
  required AuthState state,
  required LoginGoogleSignInCubit launchCubit,
  required bool shouldSkipAutoSignIn,
  required LoginAuthBlocTransitionMessages messages,
  required void Function(UserEntity user) onNavigateAfterAuth,
  required void Function(String message, TilawaFeedbackVariant variant)
  showToast,
}) {
  state.when(
    initial: () {},
    loading: () {},
    authenticated: (UserEntity user) {
      launchCubit.onAuthenticated();
      onNavigateAfterAuth(user);
    },
    unauthenticated: () {
      final bool manualCancel = launchCubit.state.awaitingManualResult;
      launchCubit.clearLaunchPending();
      if (manualCancel) {
        launchCubit.onManualSignInCancelled();
        showToast(
          messages.googleSignInCancelled,
          TilawaFeedbackVariant.info,
        );
      } else if (shouldSkipAutoSignIn) {
        launchCubit.onManualSignInCancelled();
      }
    },
    error: (String message) {
      launchCubit.onTerminalAuthState();
      showToast(
        _visibleAuthErrorMessage(message, messages),
        TilawaFeedbackVariant.error,
      );
    },
    noGoogleAccounts: () {
      launchCubit.onTerminalAuthState();
      showToast(
        messages.noGoogleAccounts,
        TilawaFeedbackVariant.info,
      );
    },
  );
}

String _visibleAuthErrorMessage(
  String message,
  LoginAuthBlocTransitionMessages messages,
) {
  return switch (message) {
    AuthErrorKey.appCheckFailed =>
      messages.appCheckFailed.isNotEmpty
          ? messages.appCheckFailed
          : messages.authErrorFallback,
    AuthErrorKey.deviceRegistrationFailed =>
      messages.deviceRegistrationFailed.isNotEmpty
          ? messages.deviceRegistrationFailed
          : messages.authErrorFallback,
    ServerActionFailureKey.offline =>
      messages.serverActionOffline.isNotEmpty
          ? messages.serverActionOffline
          : messages.authErrorFallback,
    '' => messages.authErrorFallback,
    _ when isAppCheckAuthErrorMessage(message) =>
      messages.appCheckFailed.isNotEmpty
          ? messages.appCheckFailed
          : messages.authErrorFallback,
    _ when isNetworkConnectivityErrorMessage(message) =>
      messages.serverActionOffline.isNotEmpty
          ? messages.serverActionOffline
          : messages.authErrorFallback,
    _ => messages.localizeAuthError(message),
  };
}
