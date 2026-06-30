import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';

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

  Future<void> call() async {
    try {
      await _authRepository.authStateChanges.first.timeout(startupTimeout);
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
}
