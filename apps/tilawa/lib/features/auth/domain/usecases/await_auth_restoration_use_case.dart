import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';

import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Waits for Firebase Auth to finish restoring persisted credentials.
///
/// [AuthRepository.currentUser] can be null briefly on cold start even when the
/// user is signed in. Startup routing must await the first [authStateChanges]
/// emission before choosing login vs home.
@injectable
class AwaitAuthRestorationUseCase {
  AwaitAuthRestorationUseCase(this._authRepository);

  static const Duration startupTimeout = Duration(seconds: 3);

  final AuthRepository _authRepository;

  Future<void> call({UserEntity? sessionUser}) async {
    if (_authRepository.currentUser != null) {
      logger.d(
        '[DebugNotificationAuthFlow] auth restoration skipped '
        'signedIn=true',
      );
      return;
    }

    try {
      final DateTime deadline = DateTime.now().add(startupTimeout);
      await _waitForInitialAuthEmission(deadline);

      if (_authRepository.currentUser != null) {
        logger.d(
          '[DebugNotificationAuthFlow] auth restoration completed '
          'signedIn=true',
        );
        return;
      }

      if (sessionUser != null) {
        await _waitForSessionUser(sessionUser, deadline);
      }

      logger.d(
        '[DebugNotificationAuthFlow] auth restoration completed '
        'signedIn=${_authRepository.currentUser != null}',
      );
    } on TimeoutException {
      logger.d(
        '[DebugNotificationAuthFlow] auth restoration timed out after '
        '${startupTimeout.inSeconds}s '
        'signedIn=${_authRepository.currentUser != null}',
      );
    } catch (_) {
      logger.d(
        '[DebugNotificationAuthFlow] auth restoration finished without '
        'emission signedIn=${_authRepository.currentUser != null}',
      );
    }
  }

  Future<void> _waitForInitialAuthEmission(DateTime deadline) async {
    final Duration remaining = deadline.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      throw TimeoutException('auth restoration deadline elapsed');
    }

    await _authRepository.authStateChanges.first.timeout(remaining);
  }

  Future<void> _waitForSessionUser(
    UserEntity sessionUser,
    DateTime deadline,
  ) async {
    final Duration remaining = deadline.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      return;
    }

    try {
      await _authRepository.authStateChanges
          .where((UserEntity? user) => user?.id == sessionUser.id)
          .timeout(remaining)
          .first;
    } on TimeoutException {
      // Caller logs final signedIn state.
    }
  }
}
