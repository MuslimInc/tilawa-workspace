import '../bloc/auth_bloc.dart';

/// Whether [LoginAuthBlocListener] should react to an auth transition.
bool shouldLoginAuthBlocListen(AuthState previous, AuthState current) {
  if (current is AuthAuthenticated && previous is! AuthAuthenticated) {
    return true;
  }
  if (current is AuthError && previous is! AuthError) {
    return true;
  }
  if (current is AuthNoGoogleAccounts) {
    return true;
  }
  return current is AuthUnauthenticated && previous is AuthLoading;
}
