import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/presentation/services/email_auth_route_guard.dart';

void main() {
  group('isLoginChildEmailAuthRoute', () {
    test('matches nested email auth routes', () {
      check(isLoginChildEmailAuthRoute('/login/register')).isTrue();
      check(isLoginChildEmailAuthRoute('/login/email')).isTrue();
      check(isLoginChildEmailAuthRoute('/login/forgot-password')).isTrue();
    });

    test('ignores login root', () {
      check(isLoginChildEmailAuthRoute('/login')).isFalse();
    });
  });

  group('isLoginSurfaceHandlingAuthTransitions', () {
    test('handles auth on login root only', () {
      check(isLoginSurfaceHandlingAuthTransitions('/login')).isTrue();
      check(isLoginSurfaceHandlingAuthTransitions('/login/register')).isFalse();
    });
  });
}
