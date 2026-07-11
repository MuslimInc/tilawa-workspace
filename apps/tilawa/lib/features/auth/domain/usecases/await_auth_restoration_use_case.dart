import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';

import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Terminal result of a cold-start restoration wait.
enum AuthRestorationOutcome {
  /// Firebase Auth has a restored user.
  restored,

  /// No user was expected (no persisted hint) and none is present.
  unauthenticated,

  /// A user *was* expected (persisted hint) but restoration did not surface a
  /// user within the deadline. Callers must NOT treat this as a logout — the
  /// persisted session is presumed intact and re-verified by the live streams.
  pendingUnresolved,
}

/// Waits for Firebase Auth to finish restoring persisted credentials.
///
/// [AuthRepository.currentUser] is transiently null on Android cold start even
/// when the user is signed in, and FlutterFire's [authStateChanges] can emit a
/// premature `null` before the persisted user loads from disk. Awaiting the
/// raw first emission therefore mis-reads a signed-in user as logged out.
///
/// When a [sessionUser] hint is supplied (see
/// [GetPersistedAuthenticatedUserUseCase]) we wait for the first *non-null*
/// emission up to [startupTimeout] instead of the first raw event. With no
/// hint there is nothing to restore, so we return immediately and keep the
/// login path fast.
@injectable
class AwaitAuthRestorationUseCase {
  AwaitAuthRestorationUseCase(this._authRepository);

  static const Duration startupTimeout = Duration(seconds: 3);

  final AuthRepository _authRepository;

  Future<AuthRestorationOutcome> call({UserEntity? sessionUser}) async {
    if (_authRepository.currentUser != null) {
      _log(source: 'startup-check', outcome: 'restored', signedIn: true);
      return AuthRestorationOutcome.restored;
    }

    // No persisted user was ever recorded for this install → genuinely logged
    // out. Do not stall the login path waiting for an emission that never
    // carries a user.
    if (sessionUser == null) {
      _log(source: 'startup-check', outcome: 'unauthenticated', signedIn: false);
      return AuthRestorationOutcome.unauthenticated;
    }

    try {
      final UserEntity? restored = await _authRepository.authStateChanges
          .firstWhere((UserEntity? user) => user != null)
          .timeout(startupTimeout);
      final bool signedIn = restored != null || _authRepository.currentUser != null;
      _log(
        source: 'firebase-listener',
        outcome: signedIn ? 'restored' : 'pendingUnresolved',
        signedIn: signedIn,
      );
      return signedIn
          ? AuthRestorationOutcome.restored
          : AuthRestorationOutcome.pendingUnresolved;
    } on TimeoutException {
      final bool signedIn = _authRepository.currentUser != null;
      _log(
        source: 'firebase-listener',
        outcome: signedIn ? 'restored' : 'pendingUnresolved',
        signedIn: signedIn,
        reason: 'timeout',
      );
      return signedIn
          ? AuthRestorationOutcome.restored
          : AuthRestorationOutcome.pendingUnresolved;
    } catch (_) {
      // Stream closed without a non-null emission. Treat as unresolved (not a
      // logout) because a hint said a user should exist.
      final bool signedIn = _authRepository.currentUser != null;
      _log(
        source: 'firebase-listener',
        outcome: signedIn ? 'restored' : 'pendingUnresolved',
        signedIn: signedIn,
        reason: 'stream-closed',
      );
      return signedIn
          ? AuthRestorationOutcome.restored
          : AuthRestorationOutcome.pendingUnresolved;
    }
  }

  void _log({
    required String source,
    required String outcome,
    required bool signedIn,
    String? reason,
  }) {
    logger.d(
      '[DebugNotificationAuthFlow] auth restoration completed '
      'signedIn=$signedIn '
      'AUTH_STATE_CHANGE source=$source outcome=$outcome '
      'firebaseCurrentUserPresent=${_authRepository.currentUser != null}'
      '${reason == null ? '' : ' reason=$reason'}',
    );
  }
}
