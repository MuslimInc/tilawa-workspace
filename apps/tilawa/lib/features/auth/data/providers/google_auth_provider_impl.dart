import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa/core/logging/app_logger.dart';

import '../services/android_sign_in_platform_policy.dart';
import '../services/google_sign_in_session_tracker.dart';
import '../../debug/tilawa_gsignin_debug_log.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/providers/auth_provider_interface.dart';

@LazySingleton(as: AuthProviderInterface)
class GoogleAuthProviderImpl implements AuthProviderInterface {
  GoogleAuthProviderImpl(
    this._firebaseAuth,
    this._googleSignIn,
    this._platformPolicy,
    this._sessionTracker,
  );
  static const Duration signInTimeout = Duration(seconds: 60);

  /// Transsion/XOS: [HiddenActivity] can be torn down without completing the
  /// Dart future; fail faster so the login screen can show the fallback panel.
  static const Duration transsionSignInTimeout = Duration(seconds: 15);

  /// CM bottom sheets can hang on some OEMs (e.g. Infinix XOS); cap wait time
  /// so [authenticate] account-chooser can run as fallback.
  static const Duration credentialManagerTimeout = Duration(seconds: 15);

  /// Lets a timed-out [HiddenActivity] finish tearing down before starting
  /// a second Credential Manager session (avoids `counts:2` overlap on XOS).
  static const Duration credentialManagerTeardownDelay = Duration(
    milliseconds: 500,
  );
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final AndroidSignInPlatformPolicy _platformPolicy;
  final GoogleSignInSessionTracker _sessionTracker;

  Duration get _interactiveSignInTimeout => _platformPolicy.skipAutomaticSignIn
      ? transsionSignInTimeout
      : signInTimeout;

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
    // #region agent log
    tilawaGSignInDebug(
      'signIn started',
      hypothesisId: 'H3',
      data: <String, Object?>{
        'timeoutSec': _interactiveSignInTimeout.inSeconds,
        'transsion': _platformPolicy.skipAutomaticSignIn,
      },
    );
    // #endregion
    _sessionTracker.markStarted();
    try {
      final GoogleSignInAccount googleUser = await _signInAccount().timeout(
        _interactiveSignInTimeout,
      );
      // #region agent log
      tilawaGSignInDebug(
        'signIn account obtained',
        hypothesisId: 'H3',
        data: <String, Object?>{'email': googleUser.email},
      );
      // #endregion

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
      // #region agent log
      tilawaGSignInDebug(
        'signIn TIMEOUT',
        hypothesisId: 'H3',
        data: <String, Object?>{
          'timeoutSec': _interactiveSignInTimeout.inSeconds,
        },
      );
      // #endregion
      try {
        await _googleSignIn.signOut();
        // #region agent log
        tilawaGSignInDebug('signOut after TIMEOUT', hypothesisId: 'H3');
        // #endregion
      } catch (error) {
        // #region agent log
        tilawaGSignInDebug(
          'signOut after TIMEOUT failed',
          hypothesisId: 'H3',
          data: <String, Object?>{'error': error.toString()},
        );
        // #endregion
      }
      return AuthResult.failure(
        message: _signInTimeoutMessage(),
        code: 'sign-in-timeout',
      );
    } on PlatformException catch (e) {
      // #region agent log
      tilawaGSignInDebug(
        'signIn PlatformException',
        hypothesisId: 'H4',
        data: <String, Object?>{
          'code': e.code,
          'message': e.message,
        },
      );
      // #endregion
      logger.w(
        '[GoogleSignIn] PlatformException during sign-in: ${e.code}',
        error: e,
      );
      return AuthResult.failure(
        message: e.message ?? 'Google sign-in platform error',
        code: e.code,
        details: e.details?.toString(),
      );
    } on GoogleSignInException catch (e) {
      // #region agent log
      tilawaGSignInDebug(
        'signIn GoogleSignInException',
        hypothesisId: 'H4',
        data: <String, Object?>{
          'code': e.code.name,
          'description': e.description,
        },
      );
      // #endregion
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
          return const AuthResult.cancelled();
        case GoogleSignInExceptionCode.uiUnavailable:
          return AuthResult.failure(
            message: e.description ?? 'Google sign-in UI is not available',
            code: 'ui-unavailable',
            details: e.details?.toString(),
          );
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
    } finally {
      _sessionTracker.markFinished();
    }
  }

  /// Tries Credential Manager (silent + bottom sheet), then the standard
  /// account-chooser dialog ([GoogleSignIn.authenticate]) when CM fails,
  /// times out, or returns no credential. User dismissal of the CM sheet
  /// (`canceled`) does not open a second UI.
  Future<GoogleSignInAccount> _signInAccount() async {
    await _platformPolicy.warmUp();

    // Transsion/XOS: lightweight CM always hangs and leaves [HiddenActivity]
    // alive; starting authenticate() while it is still up yields `canceled`.
    if (_platformPolicy.skipAutomaticSignIn) {
      logger.i(
        '[GoogleSignIn] Transsion OEM: skipping CM sheet → account chooser',
      );
      return _authenticateWithButtonFlow();
    }

    final GoogleSignInAccount? lightweightAccount =
        await _tryCredentialManagerSignIn();
    if (lightweightAccount != null) {
      return lightweightAccount;
    }

    logger.i('[GoogleSignIn] using account-chooser button flow');
    return _authenticateWithButtonFlow();
  }

  Future<GoogleSignInAccount?> _tryCredentialManagerSignIn() async {
    try {
      final Future<GoogleSignInAccount?>? lightweight = _googleSignIn
          .attemptLightweightAuthentication(reportAllExceptions: true);
      if (lightweight == null) {
        return null;
      }
      return await lightweight.timeout(credentialManagerTimeout);
    } on TimeoutException {
      logger.i(
        '[GoogleSignIn] Credential Manager sheet timed out; '
        'clearing credential state before button flow',
      );
      await _resetCredentialManagerAfterFailure();
      return null;
    } on GoogleSignInException catch (e) {
      if (_shouldFallbackToButtonFlowAfterCredentialManager(e)) {
        logger.i(
          '[GoogleSignIn] Credential Manager failed (${e.code.name}); '
          'clearing credential state before button flow',
        );
        await _resetCredentialManagerAfterFailure();
        return null;
      }
      rethrow;
    }
  }

  Future<void> _resetCredentialManagerAfterFailure() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Best-effort: drop any in-flight CM session before authenticate().
    }
    await Future<void>.delayed(credentialManagerTeardownDelay);
  }

  String _signInTimeoutMessage() {
    if (_platformPolicy.skipAutomaticSignIn) {
      return 'Sign-in timed out. If the account picker did not appear, press '
          'back and try again, or use the options below.';
    }
    return 'Sign-in timed out';
  }

  Future<GoogleSignInAccount> _authenticateWithButtonFlow() async {
    if (!_googleSignIn.supportsAuthenticate()) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.uiUnavailable,
        description: 'Interactive Google Sign-In is not supported',
      );
    }
    logger.i(
      '[GoogleSignIn] authenticate() starting (button / account chooser)',
    );
    // #region agent log
    tilawaGSignInDebug('authenticate() calling', hypothesisId: 'H5');
    // #endregion
    try {
      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      // #region agent log
      tilawaGSignInDebug(
        'authenticate() returned',
        hypothesisId: 'H5',
        data: <String, Object?>{'email': account.email},
      );
      // #endregion
      return account;
    } on PlatformException catch (error) {
      // #region agent log
      tilawaGSignInDebug(
        'authenticate() PlatformException',
        hypothesisId: 'H4',
        data: <String, Object?>{
          'code': error.code,
          'message': error.message,
        },
      );
      // #endregion
      logger.w(
        '[GoogleSignIn] authenticate PlatformException: ${error.code}',
        error: error,
      );
      throw GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: error.message,
        details: error.details,
      );
    }
  }

  bool _shouldFallbackToButtonFlowAfterCredentialManager(
    GoogleSignInException exception,
  ) {
    switch (exception.code) {
      case GoogleSignInExceptionCode.canceled:
        return false;
      case GoogleSignInExceptionCode.uiUnavailable:
      case GoogleSignInExceptionCode.unknownError:
      case GoogleSignInExceptionCode.interrupted:
        return true;
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
      case GoogleSignInExceptionCode.userMismatch:
        return false;
    }
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
