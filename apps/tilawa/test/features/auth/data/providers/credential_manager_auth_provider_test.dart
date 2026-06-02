import 'package:credential_manager/credential_manager.dart' hide User;
import 'package:firebase_auth/firebase_auth.dart';
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
  });
}
