import 'package:credential_manager/credential_manager.dart' hide User;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/providers/auth_provider_interface.dart';
import '../services/credential_manager_initializer.dart';

@LazySingleton()
class CredentialManagerAuthProvider implements AuthProviderInterface {
  CredentialManagerAuthProvider(
    this._firebaseAuth,
    this._credentialManager,
    this._credentialManagerInitializer,
  );
  final FirebaseAuth _firebaseAuth;
  final CredentialManager _credentialManager;
  final CredentialManagerInitializer _credentialManagerInitializer;

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) {
        return null;
      }
      return _mapFirebaseUserToUserEntity(firebaseUser);
    });
  }

  @override
  Future<AuthResult> signIn() async {
    try {
      await _credentialManagerInitializer.ensureReady();
      final GoogleIdTokenCredential? credential = await _credentialManager
          .saveGoogleCredential();

      if (credential == null) {
        return const AuthResult.cancelled();
      }

      // Create a new Firebase credential
      final OAuthCredential firebaseCredential = GoogleAuthProvider.credential(
        idToken: credential.idToken,
      );

      // Once signed in, return the UserCredential
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(firebaseCredential);

      final UserEntity user = _mapFirebaseUserToUserEntity(
        userCredential.user!,
      );

      return AuthResult.success(user: user);
    } on PlatformException catch (e) {
      if (e.code == '204' ||
          (e.message?.contains('No credentials available') ?? false) ||
          (e.message?.contains('Login failed') ?? false)) {
        return const AuthResult.cancelled();
      }
      return AuthResult.failure(
        message: e.message ?? 'Authentication failed',
        code: e.code,
      );
    } on CredentialException catch (e) {
      if (_isUserCancellation(e)) {
        return const AuthResult.cancelled();
      }
      return AuthResult.failure(message: e.message, code: e.code.toString());
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        message: e.message ?? 'Firebase authentication failed',
        code: e.code,
      );
    } catch (e) {
      final errorString = e.toString();
      if (errorString.contains('PlatformException') &&
          (errorString.contains('204') ||
              errorString.contains('No credentials available') ||
              errorString.contains('Login failed'))) {
        return const AuthResult.cancelled();
      }
      return AuthResult.failure(message: errorString);
    }
  }

  /// The credential_manager plugin converts every [PlatformException] into a
  /// [CredentialException] before it reaches app code, and its
  /// save-Google-credential flow has no dedicated catch for the native
  /// GetCredentialCancellationException — dismissing the sign-in sheet comes
  /// back as the generic 204 "Login failed", with the cancellation visible
  /// only in the native stack trace carried in [CredentialException.details].
  bool _isUserCancellation(CredentialException e) {
    switch (e.code) {
      case 201: // Login cancelled
      case 202: // No credentials found
      case 207: // No Google account; plugin launched account settings
        return true;
      case 204:
        return e.details?.toString().toLowerCase().contains('cancel') ?? false;
      default:
        return false;
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    try {
      await _credentialManager.logout();
    } catch (_) {
      // Logout is best-effort after Firebase sign-out.
    }
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
      await _reauthenticateCurrentGoogleUser(user);
      await _firebaseAuth.currentUser?.delete();
    }

    try {
      await _credentialManager.logout();
    } catch (_) {
      // Best-effort cleanup after account deletion.
    }
  }

  /// Re-authenticates the signed-in Firebase user with their saved Google
  /// account. Uses [getCredentials], not [CredentialManager.saveGoogleCredential],
  /// which is a sign-in/save flow and can switch accounts.
  Future<void> _reauthenticateCurrentGoogleUser(User user) async {
    await _credentialManagerInitializer.ensureReady();
    try {
      final Credentials credentials = await _credentialManager.getCredentials(
        fetchOptions: FetchOptionsAndroid(
          passKey: false,
          passwordCredential: false,
          googleCredential: true,
        ),
      );
      final String? idToken = credentials.googleIdTokenCredential?.idToken;
      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'requires-recent-login',
          message: 'Google re-authentication was cancelled',
        );
      }

      await user.reauthenticateWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    } on CredentialException {
      throw FirebaseAuthException(
        code: 'requires-recent-login',
        message: 'Google re-authentication was cancelled',
      );
    }
  }

  @override
  UserEntity? get currentUser {
    final User? firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return null;
    }
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
