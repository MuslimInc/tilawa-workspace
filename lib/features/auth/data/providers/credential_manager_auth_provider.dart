import 'package:credential_manager/credential_manager.dart' hide User;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/features/auth/domain/entities/auth_result.dart';
import 'package:muzakri/features/auth/domain/entities/user_entity.dart';
import 'package:muzakri/features/auth/domain/providers/auth_provider_interface.dart';

@LazySingleton()
class CredentialManagerAuthProvider implements AuthProviderInterface {
  final FirebaseAuth _firebaseAuth;
  final CredentialManager _credentialManager;

  CredentialManagerAuthProvider(this._firebaseAuth, this._credentialManager);

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      return _mapFirebaseUserToUserEntity(firebaseUser);
    });
  }

  @override
  Future<AuthResult> signIn() async {
    try {
      // Use credential manager to save Google credential
      final credential = await _credentialManager.saveGoogleCredential(
        useButtonFlow: false,
      );

      if (credential == null) {
        return const AuthResult.cancelled();
      }

      // Create a new Firebase credential
      final firebaseCredential = GoogleAuthProvider.credential(
        idToken: credential.idToken,
      );

      // Once signed in, return the UserCredential
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(firebaseCredential);

      final user = _mapFirebaseUserToUserEntity(userCredential.user!);
      return AuthResult.success(user: user);
    } on CredentialException catch (e) {
      return AuthResult.failure(message: e.message, code: e.code.toString());
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        message: e.message ?? 'Firebase authentication failed',
        code: e.code,
      );
    } catch (e) {
      return AuthResult.failure(message: e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _credentialManager.logout();
  }

  @override
  UserEntity? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    return _mapFirebaseUserToUserEntity(firebaseUser);
  }

  UserEntity _mapFirebaseUserToUserEntity(User firebaseUser) {
    return UserEntity(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? '',
      photoUrl: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );
  }
}
