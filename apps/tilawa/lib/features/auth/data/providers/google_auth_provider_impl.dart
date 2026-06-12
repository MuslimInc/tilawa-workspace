import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa/core/logging/app_logger.dart';

import '../services/android_sign_in_platform_policy.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/providers/auth_provider_interface.dart';

@LazySingleton(as: AuthProviderInterface)
class GoogleAuthProviderImpl implements AuthProviderInterface {
  GoogleAuthProviderImpl(
    this._firebaseAuth,
    this._googleSignIn,
    this._platformPolicy,
  );
  static const Duration signInTimeout = Duration(seconds: 60);
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final AndroidSignInPlatformPolicy _platformPolicy;

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
    logger.i('[GoogleSignIn] sign-in started (google_sign_in)');
    try {
      final GoogleSignInAccount googleUser = await _signInAccount().timeout(
        signInTimeout,
      );

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
    } on TimeoutException {
      return const AuthResult.failure(
        message: 'Sign-in timed out',
        code: 'sign-in-timeout',
      );
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

  /// Signs in via the lightweight Credential Manager flow: silent
  /// auto-select for returning single-account users, otherwise the
  /// "Sign in with Google" bottom sheet. Falls back to the button flow
  /// (the "Choose an account" dialog, which can also add a new account)
  /// only when no credential is available at all. Dismissing the bottom
  /// sheet throws [GoogleSignInException] with `canceled` — mapped to
  /// [AuthResult.cancelled] by the caller — instead of falling through
  /// to a second sign-in UI.
  Future<GoogleSignInAccount> _signInAccount() async {
    await _platformPolicy.warmUp();
    if (_platformPolicy.skipAutomaticSignIn) {
      logger.i(
        '[GoogleSignIn] Transsion OEM: skipping lightweight Credential '
        'Manager sheet; using account-chooser button flow',
      );
      return _googleSignIn.authenticate();
    }

    final Future<GoogleSignInAccount?>? lightweight = _googleSignIn
        .attemptLightweightAuthentication(reportAllExceptions: true);
    final GoogleSignInAccount? account = lightweight == null
        ? null
        : await lightweight;
    if (account != null) {
      return account;
    }
    logger.i(
      '[GoogleSignIn] lightweight flow returned no account; using button flow',
    );
    return _googleSignIn.authenticate();
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Best-effort after Firebase sign-out.
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
      final GoogleSignInAccount googleUser = await _signInAccount().timeout(
        signInTimeout,
      );
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
