import 'package:credential_manager/credential_manager.dart' hide User;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/auth/data/providers/credential_manager_auth_provider.dart';
import 'package:tilawa/features/auth/data/services/credential_manager_initializer.dart';
import 'package:tilawa/features/auth/domain/entities/auth_result.dart';
import 'package:tilawa_core/constants/app_strings.dart';

import 'credential_manager_auth_provider_test.mocks.dart';

@GenerateMocks([
  FirebaseAuth,
  CredentialManager,
  GoogleIdTokenCredential,
  UserCredential,
  User,
])
void main() {
  late CredentialManagerAuthProvider authProvider;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockCredentialManager mockCredentialManager;
  late MockGoogleIdTokenCredential mockCredential;
  late MockUserCredential mockUserCredential;
  late MockUser mockFirebaseUser;
  late CredentialManagerInitializer credentialManagerInitializer;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockCredentialManager = MockCredentialManager();
    mockCredential = MockGoogleIdTokenCredential();
    mockUserCredential = MockUserCredential();
    mockFirebaseUser = MockUser();
    credentialManagerInitializer = CredentialManagerInitializer(
      mockCredentialManager,
    );
    when(
      mockCredentialManager.init(
        preferImmediatelyAvailableCredentials: anyNamed(
          'preferImmediatelyAvailableCredentials',
        ),
        googleClientId: anyNamed('googleClientId'),
      ),
    ).thenAnswer((_) async {});

    authProvider = CredentialManagerAuthProvider(
      mockFirebaseAuth,
      mockCredentialManager,
      credentialManagerInitializer,
    );
  });

  group('CredentialManagerAuthProvider', () {
    test(
      'signIn should return success when credential retrieval works',
      () async {
        // Arrange
        when(
          mockCredentialManager.saveGoogleCredential(),
        ).thenAnswer((_) async => mockCredential);
        when(mockCredential.idToken).thenReturn('id_token');
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
        final AuthResult result = await authProvider.signIn();

        // Assert
        verify(
          mockCredentialManager.init(
            preferImmediatelyAvailableCredentials: true,
            googleClientId: AppStrings.googleClientId,
          ),
        ).called(1);
        expect(result, isA<AuthResult>());
        result.maybeWhen(
          success: (user) {
            expect(user.id, '123');
          },
          orElse: () => fail('Expected success'),
        );
      },
    );

    test(
      'signIn should return cancelled when no credential returned',
      () async {
        // Arrange
        when(
          mockCredentialManager.saveGoogleCredential(),
        ).thenAnswer((_) async => null);

        // Act
        final AuthResult result = await authProvider.signIn();

        // Assert
        expect(result, const AuthResult.cancelled());
      },
    );

    test(
      'signIn should return cancelled when CredentialException 204 carries '
      'a native cancellation',
      () async {
        // Arrange
        when(mockCredentialManager.saveGoogleCredential()).thenThrow(
          CredentialException(
            code: 204,
            message: 'Login failed',
            details:
                'androidx.credentials.exceptions.'
                'GetCredentialCancellationException: '
                'activity is cancelled by the user.',
          ),
        );

        // Act
        final AuthResult result = await authProvider.signIn();

        // Assert
        expect(result, const AuthResult.cancelled());
      },
    );

    test(
      'signIn should return cancelled when CredentialException reports '
      'login cancelled (201)',
      () async {
        // Arrange
        when(mockCredentialManager.saveGoogleCredential()).thenThrow(
          CredentialException(
            code: 201,
            message: 'Login cancelled',
            details: null,
          ),
        );

        // Act
        final AuthResult result = await authProvider.signIn();

        // Assert
        expect(result, const AuthResult.cancelled());
      },
    );

    test(
      'signIn should return failure for a genuine CredentialException 204',
      () async {
        // Arrange
        when(mockCredentialManager.saveGoogleCredential()).thenThrow(
          CredentialException(
            code: 204,
            message: 'Login failed',
            details:
                'androidx.credentials.exceptions.'
                'GetCredentialProviderConfigurationException: '
                'Developer console is not set up correctly.',
          ),
        );

        // Act
        final AuthResult result = await authProvider.signIn();

        // Assert
        result.maybeWhen(
          failure: (message, code, details) {
            expect(message, 'Login failed');
            expect(code, '204');
            expect(
              details,
              contains('GetCredentialProviderConfigurationException'),
            );
          },
          orElse: () => fail('Expected failure'),
        );
      },
    );

    test(
      'signIn should return cancelled when CredentialException reports '
      'no credentials found (202) or account settings launch (207)',
      () async {
        for (final (int code, String message) in [
          (202, 'No credentials found'),
          (207, 'No Google account present; launched account settings'),
        ]) {
          when(mockCredentialManager.saveGoogleCredential()).thenThrow(
            CredentialException(code: code, message: message, details: null),
          );

          expect(await authProvider.signIn(), const AuthResult.cancelled());
        }
      },
    );

    test('signIn should return cancelled for PlatformException 204', () async {
      when(mockCredentialManager.saveGoogleCredential()).thenThrow(
        PlatformException(code: '204', message: 'Login failed'),
      );

      expect(await authProvider.signIn(), const AuthResult.cancelled());
    });

    test(
      'signIn should return cancelled when PlatformException reports '
      'no credentials available',
      () async {
        when(mockCredentialManager.saveGoogleCredential()).thenThrow(
          PlatformException(
            code: '16',
            message: 'No credentials available on this device',
          ),
        );

        expect(await authProvider.signIn(), const AuthResult.cancelled());
      },
    );

    test(
      'signIn should return failure with details for a genuine '
      'PlatformException',
      () async {
        when(mockCredentialManager.saveGoogleCredential()).thenThrow(
          PlatformException(
            code: '500',
            message: 'Service unavailable',
            details: 'native stack',
          ),
        );

        final AuthResult result = await authProvider.signIn();

        result.maybeWhen(
          failure: (message, code, details) {
            expect(message, 'Service unavailable');
            expect(code, '500');
            expect(details, 'native stack');
          },
          orElse: () => fail('Expected failure'),
        );
      },
    );

    test('signIn should return failure for FirebaseAuthException', () async {
      when(
        mockCredentialManager.saveGoogleCredential(),
      ).thenAnswer((_) async => mockCredential);
      when(mockCredential.idToken).thenReturn('id_token');
      when(mockFirebaseAuth.signInWithCredential(any)).thenThrow(
        FirebaseAuthException(
          code: 'invalid-credential',
          message: 'The supplied credential is malformed',
        ),
      );

      final AuthResult result = await authProvider.signIn();

      result.maybeWhen(
        failure: (message, code, details) {
          expect(message, 'The supplied credential is malformed');
          expect(code, 'invalid-credential');
        },
        orElse: () => fail('Expected failure'),
      );
    });

    test(
      'signIn should return cancelled when a stringified platform '
      'cancellation escapes the typed catches',
      () async {
        when(mockCredentialManager.saveGoogleCredential()).thenThrow(
          Exception('PlatformException(204, Login failed User cancelled)'),
        );

        expect(await authProvider.signIn(), const AuthResult.cancelled());
      },
    );

    test('signIn should return failure for unknown errors', () async {
      when(
        mockCredentialManager.saveGoogleCredential(),
      ).thenThrow(StateError('boom'));

      final AuthResult result = await authProvider.signIn();

      result.maybeWhen(
        failure: (message, code, details) => expect(message, contains('boom')),
        orElse: () => fail('Expected failure'),
      );
    });
  });

  group('CredentialManagerAuthProvider.deleteAccount', () {
    setUp(() {
      when(mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
      when(mockFirebaseUser.uid).thenReturn('uid-1');
      when(mockFirebaseUser.delete()).thenAnswer((_) async {});
      when(mockCredentialManager.logout()).thenAnswer((_) async {});
    });

    test('returns silently when no user is signed in', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      await authProvider.deleteAccount();

      verifyNever(mockFirebaseUser.delete());
      verifyNever(mockCredentialManager.logout());
    });

    test('deletes the user and logs out of the credential manager', () async {
      await authProvider.deleteAccount();

      verify(mockFirebaseUser.delete()).called(1);
      verify(mockCredentialManager.logout()).called(1);
      verifyNever(
        mockCredentialManager.getCredentials(
          passKeyOption: anyNamed('passKeyOption'),
          fetchOptions: anyNamed('fetchOptions'),
        ),
      );
    });

    test('rethrows FirebaseAuthExceptions other than recent-login', () async {
      when(mockFirebaseUser.delete()).thenThrow(
        FirebaseAuthException(code: 'network-request-failed'),
      );

      await expectLater(
        authProvider.deleteAccount(),
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'network-request-failed',
          ),
        ),
      );
      verifyNever(
        mockCredentialManager.getCredentials(
          passKeyOption: anyNamed('passKeyOption'),
          fetchOptions: anyNamed('fetchOptions'),
        ),
      );
    });

    test(
      're-authenticates with the saved Google credential and retries the '
      'delete when Firebase requires recent login',
      () async {
        int deleteCalls = 0;
        when(mockFirebaseUser.delete()).thenAnswer((_) async {
          deleteCalls++;
          if (deleteCalls == 1) {
            throw FirebaseAuthException(code: 'requires-recent-login');
          }
        });
        when(mockCredential.idToken).thenReturn('fresh_token');
        when(
          mockCredentialManager.getCredentials(
            passKeyOption: anyNamed('passKeyOption'),
            fetchOptions: anyNamed('fetchOptions'),
          ),
        ).thenAnswer(
          (_) async => Credentials(googleIdTokenCredential: mockCredential),
        );
        when(
          mockFirebaseUser.reauthenticateWithCredential(any),
        ).thenAnswer((_) async => mockUserCredential);

        await authProvider.deleteAccount();

        expect(deleteCalls, 2);
        verify(mockFirebaseUser.reauthenticateWithCredential(any)).called(1);
        verify(mockCredentialManager.logout()).called(1);
      },
    );

    test(
      'maps a missing re-auth token to a requires-recent-login cancellation',
      () async {
        when(mockFirebaseUser.delete()).thenThrow(
          FirebaseAuthException(code: 'requires-recent-login'),
        );
        when(
          mockCredentialManager.getCredentials(
            passKeyOption: anyNamed('passKeyOption'),
            fetchOptions: anyNamed('fetchOptions'),
          ),
        ).thenAnswer((_) async => Credentials());

        await expectLater(
          authProvider.deleteAccount(),
          throwsA(
            isA<FirebaseAuthException>()
                .having((e) => e.code, 'code', 'requires-recent-login')
                .having((e) => e.message, 'message', contains('cancelled')),
          ),
        );
        verifyNever(mockFirebaseUser.reauthenticateWithCredential(any));
      },
    );

    test(
      'maps a CredentialException during re-auth to requires-recent-login',
      () async {
        when(mockFirebaseUser.delete()).thenThrow(
          FirebaseAuthException(code: 'requires-recent-login'),
        );
        when(
          mockCredentialManager.getCredentials(
            passKeyOption: anyNamed('passKeyOption'),
            fetchOptions: anyNamed('fetchOptions'),
          ),
        ).thenThrow(
          CredentialException(
            code: 204,
            message: 'Login failed',
            details: 'GetCredentialCancellationException',
          ),
        );

        await expectLater(
          authProvider.deleteAccount(),
          throwsA(
            isA<FirebaseAuthException>().having(
              (e) => e.code,
              'code',
              'requires-recent-login',
            ),
          ),
        );
      },
    );

    test('ignores credential manager logout failures', () async {
      when(mockCredentialManager.logout()).thenThrow(Exception('no session'));

      await authProvider.deleteAccount();

      verify(mockFirebaseUser.delete()).called(1);
    });
  });

  group('CredentialManagerAuthProvider.signOut', () {
    test('signs out of Firebase and the credential manager', () async {
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});
      when(mockCredentialManager.logout()).thenAnswer((_) async {});

      await authProvider.signOut();

      verify(mockFirebaseAuth.signOut()).called(1);
      verify(mockCredentialManager.logout()).called(1);
    });

    test('ignores credential manager logout failures', () async {
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});
      when(mockCredentialManager.logout()).thenThrow(Exception('no session'));

      await expectLater(authProvider.signOut(), completes);
    });
  });
}
