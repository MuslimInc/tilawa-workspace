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
    test('listens when auth becomes authenticated on login root', () {
      check(
        shouldLoginAuthBlocListen(
          const AuthState.loading(),
          AuthState.authenticated(user: user),
          routeLocation: '/login',
        ),
      ).isTrue();
    });

    test('ignores authenticated transitions on register route', () {
      check(
        shouldLoginAuthBlocListen(
          const AuthState.loading(),
          AuthState.authenticated(user: user),
          routeLocation: '/login/register',
        ),
      ).isFalse();
    });

    test('ignores repeated authenticated emissions', () {
      final AuthState authenticated = AuthState.authenticated(user: user);
      check(
        shouldLoginAuthBlocListen(
          authenticated,
          authenticated,
          routeLocation: '/login',
        ),
      ).isFalse();
    });

    test('listens when auth becomes error on login root', () {
      check(
        shouldLoginAuthBlocListen(
          const AuthState.loading(),
          const AuthState.error(message: 'down'),
          routeLocation: '/login',
        ),
      ).isTrue();
    });

    test('ignores registration errors on register route', () {
      check(
        shouldLoginAuthBlocListen(
          const AuthState.loading(),
          const AuthState.error(message: 'authEmailAlreadyInUse'),
          routeLocation: '/login/register',
        ),
      ).isFalse();
    });

    test('ignores repeated error emissions', () {
      const AuthState error = AuthState.error(message: 'down');
      check(
        shouldLoginAuthBlocListen(error, error, routeLocation: '/login'),
      ).isFalse();
    });

    test('listens for noGoogleAccounts even when previous matches', () {
      check(
        shouldLoginAuthBlocListen(
          const AuthState.noGoogleAccounts(),
          const AuthState.noGoogleAccounts(),
          routeLocation: '/login',
        ),
      ).isTrue();
    });

    test('listens when loading settles to unauthenticated on login root', () {
      check(
        shouldLoginAuthBlocListen(
          const AuthState.loading(),
          const AuthState.unauthenticated(),
          routeLocation: '/login',
        ),
      ).isTrue();
    });

    test('ignores unauthenticated when previous was not loading', () {
      check(
        shouldLoginAuthBlocListen(
          const AuthState.initial(),
          const AuthState.unauthenticated(),
          routeLocation: '/login',
        ),
      ).isFalse();
    });
  });
}
