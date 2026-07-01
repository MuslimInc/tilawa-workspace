import 'package:injectable/injectable.dart';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../entities/auth_error_key.dart';
import '../services/session_revoked_notifier.dart';
import 'register_active_device_use_case.dart';

@injectable
class SyncDeviceTokenUseCase {
  SyncDeviceTokenUseCase(
    this._registerActiveDeviceUseCase,
    this._sessionRevokedNotifier,
  );

  final RegisterActiveDeviceUseCase _registerActiveDeviceUseCase;
  final SessionRevokedNotifier _sessionRevokedNotifier;

  Future<Either<Failure, void>> call(String userId) async {
    final result = await _registerActiveDeviceUseCase.syncPassive(userId);
    _notifyWhenStale(result);
    return result.fold(Left.new, (_) => const Right(null));
  }

  Future<Either<Failure, void>> registerExplicitSignIn(String userId) async {
    final result = await _registerActiveDeviceUseCase.registerExplicitSignIn(
      userId,
    );
    _notifyWhenStale(result);
    return result.fold(Left.new, (_) => const Right(null));
  }

  Future<void> removeCurrentTokenForUser(String userId) async {
    try {
      await _registerActiveDeviceUseCase.clearActiveDeviceOnSignOut(userId);
    } catch (_) {
      // Best-effort cleanup only.
    }
  }

  void _notifyWhenStale<T>(Either<Failure, T> result) {
    result.fold((failure) {
      if (failure.message == AuthErrorKey.staleDeviceRejected) {
        _sessionRevokedNotifier.notifySessionRevoked();
      }
    }, (_) {});
  }
}
