import '../bloc/auth_bloc.dart';
import 'email_auth_route_guard.dart';

/// Whether [LoginAuthBlocListener] should react to an auth transition.
bool shouldLoginAuthBlocListen(
  AuthState previous,
  AuthState current, {
  required String routeLocation,
}) {
  if (!isLoginSurfaceHandlingAuthTransitions(routeLocation)) {
    return false;
  }
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
