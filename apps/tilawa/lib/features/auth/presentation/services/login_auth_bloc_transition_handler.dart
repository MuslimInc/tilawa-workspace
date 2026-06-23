import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../bloc/auth_bloc.dart';
import '../cubit/login_google_sign_in_cubit.dart';
import 'login_auth_state_diagnostics.dart';

/// User-visible copy for login auth listener side effects.
class LoginAuthBlocTransitionMessages {
  const LoginAuthBlocTransitionMessages({
    required this.authErrorFallback,
    required this.noGoogleAccounts,
  });

  final String authErrorFallback;
  final String noGoogleAccounts;
}

/// Applies login-screen side effects for a listened [AuthState] transition.
void handleLoginAuthBlocTransition({
  required AuthState state,
  required LoginGoogleSignInCubit launchCubit,
  required bool shouldSkipAutoSignIn,
  required LoginAuthBlocTransitionMessages messages,
  required void Function() onNavigateToHome,
  required void Function(String message, TilawaFeedbackVariant variant)
  showToast,
  void Function(String message)? log,
}) {
  final void Function(String message) writeLog = log ?? (_) {};

  writeLog(
    'listener transition authState=${loginAuthStateLabel(state)}',
  );
  state.when(
    initial: () {},
    loading: () {},
    authenticated: (_) {
      launchCubit.onAuthenticated();
      onNavigateToHome();
    },
    unauthenticated: () {
      launchCubit.clearLaunchPending();
      if (shouldSkipAutoSignIn) {
        launchCubit.onManualSignInCancelled();
      }
    },
    error: (String message) {
      launchCubit.onTerminalAuthState();
      showToast(
        message.isNotEmpty ? message : messages.authErrorFallback,
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
