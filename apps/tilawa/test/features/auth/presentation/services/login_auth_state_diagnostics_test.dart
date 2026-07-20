import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/auth/presentation/services/login_auth_state_diagnostics.dart';

void main() {
  final UserEntity user = UserEntity(
    id: '1',
    email: 'a@b.c',
    displayName: 'A',
    createdAt: DateTime.utc(2024),
  );

  group('loginSignInButtonsLoading', () {
    test('true while AuthBloc is loading', () {
      expect(
        loginSignInButtonsLoading(
          authState: const AuthState.loading(),
          isLaunchPending: false,
          sessionInFlight: false,
        ),
        isTrue,
      );
    });

    test('true while launch is pending', () {
      expect(
        loginSignInButtonsLoading(
          authState: const AuthState.unauthenticated(),
          isLaunchPending: true,
          sessionInFlight: false,
        ),
        isTrue,
      );
    });

    test('true after authenticated while session still in flight', () {
      expect(
        loginSignInButtonsLoading(
          authState: AuthState.authenticated(user: user),
          isLaunchPending: false,
          sessionInFlight: true,
        ),
        isTrue,
      );
    });

    test('false after cancel even if session flag still in flight', () {
      expect(
        loginSignInButtonsLoading(
          authState: const AuthState.unauthenticated(),
          isLaunchPending: false,
          sessionInFlight: true,
        ),
        isFalse,
      );
    });

    test('false after error even if session flag still in flight', () {
      expect(
        loginSignInButtonsLoading(
          authState: const AuthState.error(message: 'x'),
          isLaunchPending: false,
          sessionInFlight: true,
        ),
        isFalse,
      );
    });
  });
}
