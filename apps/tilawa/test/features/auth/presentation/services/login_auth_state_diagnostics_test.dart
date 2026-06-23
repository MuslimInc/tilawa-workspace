import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/auth/presentation/services/login_auth_state_diagnostics.dart';

void main() {
  final UserEntity user = UserEntity(
    id: '1',
    email: 'a@b.com',
    displayName: 'User',
    createdAt: DateTime.utc(2024),
  );

  group('loginAuthStateLabel', () {
    test('maps each auth state to a debug label', () {
      check(loginAuthStateLabel(const AuthState.initial())).equals('initial');
      check(loginAuthStateLabel(const AuthState.loading())).equals('loading');
      check(
        loginAuthStateLabel(AuthState.authenticated(user: user)),
      ).equals('authenticated');
      check(
        loginAuthStateLabel(const AuthState.unauthenticated()),
      ).equals('unauthenticated');
      check(
        loginAuthStateLabel(const AuthState.error(message: 'boom')),
      ).equals('error(boom)');
      check(
        loginAuthStateLabel(const AuthState.noGoogleAccounts()),
      ).equals('noGoogleAccounts');
    });
  });

  group('loginAuthButtonEnabled', () {
    test('is false only while loading', () {
      check(loginAuthButtonEnabled(const AuthState.initial())).isTrue();
      check(loginAuthButtonEnabled(const AuthState.loading())).isFalse();
      check(
        loginAuthButtonEnabled(AuthState.authenticated(user: user)),
      ).isTrue();
    });
  });

  group('loginShouldDispatchAutoSignIn', () {
    test('dispatches for initial, unauthenticated, and error only', () {
      check(loginShouldDispatchAutoSignIn(const AuthState.initial())).isTrue();
      check(
        loginShouldDispatchAutoSignIn(const AuthState.unauthenticated()),
      ).isTrue();
      check(
        loginShouldDispatchAutoSignIn(const AuthState.error(message: 'x')),
      ).isTrue();
      check(loginShouldDispatchAutoSignIn(const AuthState.loading())).isFalse();
      check(
        loginShouldDispatchAutoSignIn(AuthState.authenticated(user: user)),
      ).isFalse();
      check(
        loginShouldDispatchAutoSignIn(const AuthState.noGoogleAccounts()),
      ).isFalse();
    });
  });

  group('loginShouldAttemptAutoSignIn', () {
    test('blocks when account deletion suppresses auto sign-in', () {
      check(
        loginShouldAttemptAutoSignIn(
          suppressForAccountDeletion: true,
          authState: const AuthState.initial(),
        ),
      ).isFalse();
    });

    test('delegates to dispatch rules when not suppressed', () {
      check(
        loginShouldAttemptAutoSignIn(
          suppressForAccountDeletion: false,
          authState: const AuthState.initial(),
        ),
      ).isTrue();
      check(
        loginShouldAttemptAutoSignIn(
          suppressForAccountDeletion: false,
          authState: const AuthState.loading(),
        ),
      ).isFalse();
    });
  });
}
