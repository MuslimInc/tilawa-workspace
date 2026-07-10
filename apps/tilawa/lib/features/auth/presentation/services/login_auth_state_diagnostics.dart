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

/// Whether [AuthBloc] loading changed enough to rebuild the sign-in button.
bool loginAuthAffectsGoogleSignInButtonLoading(
  AuthState previous,
  AuthState current,
) {
  return (previous is AuthLoading) != (current is AuthLoading);
}

/// Whether launch cubit pending state affects the sign-in button.
bool loginLaunchAffectsGoogleSignInButtonLoading(
  LoginGoogleSignInState previous,
  LoginGoogleSignInState current,
) {
  return previous.isLaunchPending != current.isLaunchPending;
}
