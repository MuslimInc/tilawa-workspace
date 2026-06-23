import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/auth/presentation/services/login_auth_bloc_listener_policy.dart';

void main() {
  final UserEntity user = UserEntity(
    id: '1',
    email: 'a@b.com',
    displayName: 'User',
    createdAt: DateTime.utc(2024),
  );

  group('shouldLoginAuthBlocListen', () {
    test('listens when auth becomes authenticated', () {
      check(
        shouldLoginAuthBlocListen(
          const AuthState.loading(),
          AuthState.authenticated(user: user),
        ),
      ).isTrue();
    });

    test('ignores repeated authenticated emissions', () {
      final AuthState authenticated = AuthState.authenticated(user: user);
      check(
        shouldLoginAuthBlocListen(authenticated, authenticated),
      ).isFalse();
    });

    test('listens when auth becomes error', () {
      check(
        shouldLoginAuthBlocListen(
          const AuthState.loading(),
          const AuthState.error(message: 'down'),
        ),
      ).isTrue();
    });

    test('ignores repeated error emissions', () {
      const AuthState error = AuthState.error(message: 'down');
      check(shouldLoginAuthBlocListen(error, error)).isFalse();
    });

    test('listens for noGoogleAccounts even when previous matches', () {
      check(
        shouldLoginAuthBlocListen(
          const AuthState.noGoogleAccounts(),
          const AuthState.noGoogleAccounts(),
        ),
      ).isTrue();
    });

    test('listens when loading settles to unauthenticated', () {
      check(
        shouldLoginAuthBlocListen(
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ),
      ).isTrue();
    });

    test('ignores unauthenticated when previous was not loading', () {
      check(
        shouldLoginAuthBlocListen(
          const AuthState.initial(),
          const AuthState.unauthenticated(),
        ),
      ).isFalse();
    });
  });
}
