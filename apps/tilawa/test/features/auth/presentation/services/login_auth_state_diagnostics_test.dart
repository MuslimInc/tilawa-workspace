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
}
