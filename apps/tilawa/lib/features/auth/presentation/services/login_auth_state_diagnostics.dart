import '../bloc/auth_bloc.dart';
import '../cubit/login_google_sign_in_cubit.dart';

/// Label for [AuthState] on the login screen.
String loginAuthStateLabel(AuthState state) {
  return state.when(
    initial: () => 'initial',
    loading: () => 'loading',
    authenticated: (_) => 'authenticated',
    unauthenticated: () => 'unauthenticated',
    error: (message) => 'error($message)',
    noGoogleAccounts: () => 'noGoogleAccounts',
  );
}

/// Whether the Google button should stay enabled for this [AuthState].
bool loginAuthButtonEnabled(AuthState state) => state is! AuthLoading;

/// Combined loading flag for Apple/Google buttons on the login screen.
///
/// [sessionInFlight] only keeps the button busy after a successful auth emit
/// while post-sign-in device registration finishes. It must not keep the
/// button spinning after cancel/error: [AuthBloc] emits the terminal state
/// before [GoogleSignInSessionTracker.markFinished], and that emit is the
/// last rebuild the button gets.
bool loginSignInButtonsLoading({
  required AuthState authState,
  required bool isLaunchPending,
  required bool sessionInFlight,
}) {
  return authState is AuthLoading ||
      isLaunchPending ||
      (authState is AuthAuthenticated && sessionInFlight);
}

/// Whether [AuthBloc] loading changed enough to rebuild the sign-in button.
bool loginAuthAffectsGoogleSignInButtonLoading(
  AuthState previous,
  AuthState current,
) {
  return (previous is AuthLoading) != (current is AuthLoading) ||
      (previous is AuthAuthenticated) != (current is AuthAuthenticated);
}

/// Whether launch cubit pending state affects the sign-in button.
bool loginLaunchAffectsGoogleSignInButtonLoading(
  LoginGoogleSignInState previous,
  LoginGoogleSignInState current,
) {
  return previous.isLaunchPending != current.isLaunchPending;
}
