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

    /*
    test(
      'signIn should return cancelled when authentication is cancelled',
      () async {
        // Arrange
        when(
          mockGoogleSignIn.authenticate(),
        ).thenAnswer((_) => Future<GoogleSignInAccount?>.value(null));

        // Act
        final AuthResult result = await googleAuthProvider.signIn();

        // Assert
        expect(result, const AuthResult.cancelled());
      },
    );
    */
  });
}
