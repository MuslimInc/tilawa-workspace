import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/auth/data/providers/google_auth_provider_impl.dart';
import 'package:tilawa/features/auth/domain/entities/auth_result.dart';

import 'google_auth_provider_impl_test.mocks.dart';

@GenerateMocks([
  FirebaseAuth,
  GoogleSignIn,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
  UserCredential,
  User,
])
void main() {
  late GoogleAuthProviderImpl googleAuthProvider;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockGoogleSignInAccount mockGoogleUser;
  late MockGoogleSignInAuthentication mockGoogleAuth;
  late MockUserCredential mockUserCredential;
  late MockUser mockFirebaseUser;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    mockGoogleUser = MockGoogleSignInAccount();
    mockGoogleAuth = MockGoogleSignInAuthentication();
    mockUserCredential = MockUserCredential();
    mockFirebaseUser = MockUser();

    googleAuthProvider = GoogleAuthProviderImpl(
      mockFirebaseAuth,
      mockGoogleSignIn,
    );
  });

  group('GoogleAuthProviderImpl', () {
    test('signIn should return success when login successful', () async {
      // Arrange
      when(
        mockGoogleSignIn.authenticate(),
      ).thenAnswer((_) async => mockGoogleUser);
      when(mockGoogleUser.authentication).thenReturn(mockGoogleAuth);
      when(mockGoogleAuth.idToken).thenReturn('token');
      when(
        mockFirebaseAuth.signInWithCredential(any),
      ).thenAnswer((_) async => mockUserCredential);
      when(mockUserCredential.user).thenReturn(mockFirebaseUser);
      when(mockFirebaseUser.uid).thenReturn('123');
      when(mockFirebaseUser.email).thenReturn('test@example.com');
      when(mockFirebaseUser.displayName).thenReturn('Test User');
      when(mockFirebaseUser.photoURL).thenReturn('url');
      when(mockFirebaseUser.metadata).thenReturn(UserMetadata(0, 0));

      // Act
      final AuthResult result = await googleAuthProvider.signIn();

      // Assert
      expect(result, isA<AuthResult>());
      result.maybeWhen(
        success: (user) {
          expect(user.id, '123');
        },
        orElse: () => fail('Expected success'),
      );
    });

    test('signIn should return cancelled when no idToken is returned',
        () async {
      when(
        mockGoogleSignIn.authenticate(),
      ).thenAnswer((_) async => mockGoogleUser);
      when(mockGoogleUser.authentication).thenReturn(mockGoogleAuth);
      when(mockGoogleAuth.idToken).thenReturn(null);

      expect(await googleAuthProvider.signIn(), const AuthResult.cancelled());
    });

    for (final code in [
      GoogleSignInExceptionCode.canceled,
      GoogleSignInExceptionCode.interrupted,
      GoogleSignInExceptionCode.uiUnavailable,
    ]) {
      test('signIn should return cancelled for ${code.name}', () async {
        when(
          mockGoogleSignIn.authenticate(),
        ).thenThrow(GoogleSignInException(code: code));

        expect(
          await googleAuthProvider.signIn(),
          const AuthResult.cancelled(),
        );
      });
    }

    test(
      'signIn should return failure with details for genuine sign-in errors',
      () async {
        when(mockGoogleSignIn.authenticate()).thenThrow(
          const GoogleSignInException(
            code: GoogleSignInExceptionCode.providerConfigurationError,
            description: 'Missing SHA-1 fingerprint',
            details: 'native context',
          ),
        );

        final AuthResult result = await googleAuthProvider.signIn();

        result.maybeWhen(
          failure: (message, code, details) {
            expect(message, 'Missing SHA-1 fingerprint');
            expect(code, 'providerConfigurationError');
            expect(details, 'native context');
          },
          orElse: () => fail('Expected failure'),
        );
      },
    );

    test('signIn should return failure for FirebaseAuthException', () async {
      when(
        mockGoogleSignIn.authenticate(),
      ).thenAnswer((_) async => mockGoogleUser);
      when(mockGoogleUser.authentication).thenReturn(mockGoogleAuth);
      when(mockGoogleAuth.idToken).thenReturn('token');
      when(mockFirebaseAuth.signInWithCredential(any)).thenThrow(
        FirebaseAuthException(code: 'invalid-credential', message: 'bad'),
      );

      final AuthResult result = await googleAuthProvider.signIn();

      result.maybeWhen(
        failure: (message, code, details) {
          expect(message, 'bad');
          expect(code, 'invalid-credential');
        },
        orElse: () => fail('Expected failure'),
      );
    });

    test('signIn should return failure for unknown errors', () async {
      when(mockGoogleSignIn.authenticate()).thenThrow(StateError('boom'));

      final AuthResult result = await googleAuthProvider.signIn();

      result.maybeWhen(
        failure: (message, code, details) => expect(message, contains('boom')),
        orElse: () => fail('Expected failure'),
      );
    });

    test('signOut should sign out of Firebase and Google', () async {
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});
      when(mockGoogleSignIn.signOut()).thenAnswer((_) async {});

      await googleAuthProvider.signOut();

      verify(mockFirebaseAuth.signOut()).called(1);
      verify(mockGoogleSignIn.signOut()).called(1);
    });

    test('currentUser should return null when signed out', () {
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      expect(googleAuthProvider.currentUser, isNull);
    });

    test('currentUser should map the Firebase user', () {
      when(mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
      when(mockFirebaseUser.uid).thenReturn('123');
      when(mockFirebaseUser.email).thenReturn(null);
      when(mockFirebaseUser.displayName).thenReturn(null);
      when(mockFirebaseUser.photoURL).thenReturn(null);
      when(mockFirebaseUser.metadata).thenReturn(UserMetadata(0, 0));

      final user = googleAuthProvider.currentUser;

      expect(user?.id, '123');
      expect(user?.email, '');
      expect(user?.displayName, '');
    });

    test('authStateChanges should map users and sign-outs', () async {
      when(mockFirebaseUser.uid).thenReturn('123');
      when(mockFirebaseUser.email).thenReturn('test@example.com');
      when(mockFirebaseUser.displayName).thenReturn('Test User');
      when(mockFirebaseUser.photoURL).thenReturn(null);
      when(mockFirebaseUser.metadata).thenReturn(UserMetadata(0, 0));
      when(mockFirebaseAuth.authStateChanges()).thenAnswer(
        (_) => Stream<User?>.fromIterable([null, mockFirebaseUser]),
      );

      final states = await googleAuthProvider.authStateChanges.take(2).toList();

      expect(states[0], isNull);
      expect(states[1]?.id, '123');
    });

    group('deleteAccount', () {
      setUp(() {
        when(mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
        when(mockFirebaseUser.delete()).thenAnswer((_) async {});
        when(mockGoogleSignIn.signOut()).thenAnswer((_) async {});
      });

      test('returns silently when no user is signed in', () async {
        when(mockFirebaseAuth.currentUser).thenReturn(null);

        await googleAuthProvider.deleteAccount();

        verifyNever(mockFirebaseUser.delete());
      });

      test('deletes the user and signs out of Google', () async {
        await googleAuthProvider.deleteAccount();

        verify(mockFirebaseUser.delete()).called(1);
        verify(mockGoogleSignIn.signOut()).called(1);
      });

      test('rethrows FirebaseAuthExceptions other than recent-login',
          () async {
        when(mockFirebaseUser.delete()).thenThrow(
          FirebaseAuthException(code: 'network-request-failed'),
        );

        await expectLater(
          googleAuthProvider.deleteAccount(),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('re-authenticates and retries when recent login is required',
          () async {
        int deleteCalls = 0;
        when(mockFirebaseUser.delete()).thenAnswer((_) async {
          deleteCalls++;
          if (deleteCalls == 1) {
            throw FirebaseAuthException(code: 'requires-recent-login');
          }
        });
        when(
          mockGoogleSignIn.authenticate(),
        ).thenAnswer((_) async => mockGoogleUser);
        when(mockGoogleUser.authentication).thenReturn(mockGoogleAuth);
        when(mockGoogleAuth.idToken).thenReturn('fresh_token');
        when(
          mockFirebaseUser.reauthenticateWithCredential(any),
        ).thenAnswer((_) async => mockUserCredential);

        await googleAuthProvider.deleteAccount();

        expect(deleteCalls, 2);
        verify(mockFirebaseUser.reauthenticateWithCredential(any)).called(1);
      });

      test(
          'maps a missing re-auth token to a requires-recent-login '
          'cancellation', () async {
        when(mockFirebaseUser.delete()).thenThrow(
          FirebaseAuthException(code: 'requires-recent-login'),
        );
        when(
          mockGoogleSignIn.authenticate(),
        ).thenAnswer((_) async => mockGoogleUser);
        when(mockGoogleUser.authentication).thenReturn(mockGoogleAuth);
        when(mockGoogleAuth.idToken).thenReturn(null);

        await expectLater(
          googleAuthProvider.deleteAccount(),
          throwsA(
            isA<FirebaseAuthException>()
                .having((e) => e.code, 'code', 'requires-recent-login')
                .having((e) => e.message, 'message', contains('cancelled')),
          ),
        );
        verifyNever(mockFirebaseUser.reauthenticateWithCredential(any));
      });
    });
  });
}
