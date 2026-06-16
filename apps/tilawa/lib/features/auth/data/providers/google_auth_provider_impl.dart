import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa/core/logging/app_logger.dart';

import '../services/android_sign_in_platform_policy.dart';
import '../services/google_sign_in_android_resume_bridge.dart';
import '../services/google_sign_in_session_tracker.dart';
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
  ) {
    GoogleSignInAndroidResumeBridge.instance.ensureInitialized();
  }
  static const Duration signInTimeout = Duration(seconds: 60);

  /// iOS has no Credential Manager sheet; after [GoogleSignIn.signOut] the
  /// lightweight path returns no account and must fall back to [authenticate].
  @visibleForTesting
  static bool useIosInteractiveSignInFallback = Platform.isIOS;

  /// Transsion/XOS: GMS sign-in UI (CM sheet or account chooser) can be
  /// composited invisibly behind the Flutter window. Visible GMS UI takes
  /// this activity out of [AppLifecycleState.resumed]; if we are still
  /// resumed this long after launching the flow, no UI ever appeared and
  /// the session is treated as hung instead of waiting the full timeout.
  @visibleForTesting
  static Duration transsionUiProbeDelay = const Duration(seconds: 6);

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final AndroidSignInPlatformPolicy _platformPolicy;
  final GoogleSignInSessionTracker _sessionTracker;

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
    _sessionTracker.markStarted();
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
      try {
        await _googleSignIn.signOut();
      } catch (error) {
        logger.w(
          '[GoogleSignIn] signOut after timeout failed',
          error: error,
        );
      }
      return AuthResult.failure(
        message: _signInTimeoutMessage(),
        code: 'sign-in-timeout',
      );
    } on PlatformException catch (e) {
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

  Future<GoogleSignInAccount> _signInAccount() async {
    await _platformPolicy.warmUp();

    if (useIosInteractiveSignInFallback) {
      return _tryIosSignIn();
    }

    // Android Credential Manager only (silent + bottom sheet). Does not fall
    // back to the centered account-chooser ([GoogleSignIn.authenticate]).
    return _tryCredentialManagerSignIn();
  }

  Future<GoogleSignInAccount> _tryIosSignIn() async {
    final GoogleSignInAccount? lightweightAccount =
        await _attemptLightweightAccount();
    if (lightweightAccount != null) {
      return lightweightAccount;
    }
    return _authenticateWithButtonFlow();
  }

  Future<GoogleSignInAccount?> _attemptLightweightAccount() async {
    final Future<GoogleSignInAccount?>? lightweight = _googleSignIn
        .attemptLightweightAuthentication(reportAllExceptions: true);
    if (lightweight == null) {
      return null;
    }
    try {
      return await lightweight;
    } on GoogleSignInException catch (error) {
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
          return null;
        case GoogleSignInExceptionCode.uiUnavailable:
        case GoogleSignInExceptionCode.unknownError:
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
        case GoogleSignInExceptionCode.userMismatch:
          rethrow;
      }
    }
  }

  Future<GoogleSignInAccount> _tryCredentialManagerSignIn() async {
    final Future<GoogleSignInAccount?>? lightweight = _googleSignIn
        .attemptLightweightAuthentication(reportAllExceptions: true);
    if (lightweight == null) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.uiUnavailable,
        description: 'Credential Manager sign-in is not supported',
      );
    }
    final GoogleSignInAccount? account = await _waitForInteractiveUi(
      lightweight,
      stageTimeout: signInTimeout,
    );
    if (account == null) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
      );
    }
    return account;
  }

  /// Waits for an interactive GMS sign-in [operation], capped at
  /// [stageTimeout].
  ///
  /// Transsion/XOS only: the CM sheet / account chooser can be composited
  /// invisibly (the original Infinix bug). If the app is still
  /// [AppLifecycleState.resumed] after [transsionUiProbeDelay] — meaning no
  /// GMS UI ever covered it — throws [TimeoutException] immediately so the
  /// caller can fall back. Once UI is confirmed visible the user gets the
  /// full [signInTimeout] regardless of [stageTimeout].
  Future<T> _waitForInteractiveUi<T>(
    Future<T> operation, {
    required Duration stageTimeout,
  }) async {
    if (!_platformPolicy.skipAutomaticSignIn) {
      return operation.timeout(stageTimeout);
    }
    try {
      return await operation.timeout(transsionUiProbeDelay);
    } on TimeoutException {
      final AppLifecycleState? lifecycle =
          SchedulerBinding.instance.lifecycleState;
      if (lifecycle == AppLifecycleState.resumed) {
        // No GMS UI ever covered the app — invisible-overlay hang.
        rethrow;
      }
      return operation.timeout(signInTimeout);
    }
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
    try {
      final GoogleSignInAccount account = await _waitForInteractiveUi(
        _googleSignIn.authenticate(),
        stageTimeout: signInTimeout,
      );
      return account;
    } on PlatformException catch (error) {
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
      // Re-auth for account deletion must not open Credential Manager — only
      // the explicit account-chooser flow.
      final GoogleSignInAccount googleUser = await _authenticateWithButtonFlow()
          .timeout(
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
