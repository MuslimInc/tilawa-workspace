import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/features/auth/domain/entities/auth_result.dart';
import 'package:muzakri/features/auth/domain/entities/user_entity.dart';
import 'package:muzakri/features/auth/domain/providers/auth_provider_interface.dart';

@LazySingleton()
class GoogleAuthProviderImpl implements AuthProviderInterface {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  GoogleAuthProviderImpl(this._firebaseAuth, this._googleSignIn);

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      return _mapFirebaseUserToUser(firebaseUser);
    });
  }

  @override
  Future<AuthResult> signIn() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null) {
        return const AuthResult.cancelled();
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      final user = _mapFirebaseUserToUser(userCredential.user!);
      return AuthResult.success(user: user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        message: e.message ?? 'Authentication failed',
        code: e.code,
      );
    } catch (e) {
      return AuthResult.failure(message: e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }

  @override
  UserEntity? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    return _mapFirebaseUserToUser(firebaseUser);
  }

  UserEntity _mapFirebaseUserToUser(User firebaseUser) {
    return UserEntity(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? '',
      photoUrl: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );
  }
}
