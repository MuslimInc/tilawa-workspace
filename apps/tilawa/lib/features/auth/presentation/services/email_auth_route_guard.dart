/// Whether [location] is a nested email-auth screen under [/login].
bool isLoginChildEmailAuthRoute(String location) {
  return location.endsWith('/register') ||
      location.endsWith('/email') ||
      location.endsWith('/forgot-password');
}

/// Whether the login surface should react to global [AuthBloc] transitions.
///
/// Child routes (register, email login, forgot password) own their own auth UX.
bool isLoginSurfaceHandlingAuthTransitions(String location) {
  return !isLoginChildEmailAuthRoute(location);
}
