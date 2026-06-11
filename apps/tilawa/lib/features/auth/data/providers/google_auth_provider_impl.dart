import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/providers/auth_provider_interface.dart';

@LazySingleton()
class GoogleAuthProviderImpl implements AuthProviderInterface {
  GoogleAuthProviderImpl(this._firebaseAuth, this._googleSignIn);
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) {
        return null;
      }
      return _mapFirebaseUserToUser(firebaseUser);
    });
  }

  @override
  Future<AuthResult> signIn() async {
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null) {
        return const AuthResult.cancelled();
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      final UserEntity user = _mapFirebaseUserToUser(userCredential.user!);

      return AuthResult.success(user: user);
    } on GoogleSignInException catch (e) {
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
        case GoogleSignInExceptionCode.uiUnavailable:
          return const AuthResult.cancelled();
        case GoogleSignInExceptionCode.unknownError:
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
        case GoogleSignInExceptionCode.userMismatch:
          return AuthResult.failure(
            message: e.description ?? 'Authentication failed',
            code: e.code.name,
            details: e.details?.toString(),
          );
      }
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
  Future<void> deleteAccount() async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      return;
    }

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') {
        rethrow;
      }
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'requires-recent-login',
          message: 'Google re-authentication was cancelled',
        );
      }
      await user.reauthenticateWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      await _firebaseAuth.currentUser?.delete();
    }

    await _googleSignIn.signOut();
  }

  @override
  UserEntity? get currentUser {
    final User? firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return null;
    }
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
