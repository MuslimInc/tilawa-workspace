import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/core/network/network_error_message.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../entities/session_validity_result.dart';
import '../repositories/session_validity_repository.dart';
import '../services/token_sync_cache.dart';

@injectable
class CheckSessionValidityUseCase {
  CheckSessionValidityUseCase(this._repository, this._tokenSyncCache);

  final SessionValidityRepository _repository;
  final TokenSyncCache _tokenSyncCache;

  /// Returns [SessionValidityResult.valid] when local session matches server.
  Future<Either<Failure, SessionValidityResult>> call(String userId) async {
    try {
      final localEpoch = await _tokenSyncCache.getSessionEpoch() ?? 0;
      final localActiveDeviceId = await _tokenSyncCache.getActiveDeviceId();
      if (localActiveDeviceId == null || localActiveDeviceId.isEmpty) {
        return const Right(SessionValidityResult.verificationUnknown);
      }

      final serverResult = await _repository.fetchServerSession(userId);
      return serverResult.fold(
        (failure) {
          if (failure.message == SessionValidityFailureKey.network) {
            return const Right(SessionValidityResult.verificationUnknown);
          }
          return Left(failure);
        },
        (server) {
          final isValid =
              localEpoch == server.epoch &&
              localActiveDeviceId == server.activeDeviceId;
          if (isValid) {
            return const Right(SessionValidityResult.valid);
          }
          if (localEpoch > 0 &&
              server.epoch == 0 &&
              server.activeDeviceId.isEmpty) {
            return const Right(SessionValidityResult.verificationUnknown);
          }
          return const Right(SessionValidityResult.stale);
        },
      );
    } on TimeoutException catch (error) {
      logger.d('Session validity check timed out', error: error);
      return const Right(SessionValidityResult.verificationUnknown);
    } catch (error, stackTrace) {
      if (isNetworkConnectivityErrorMessage(error.toString())) {
        logger.d(
          'Session validity check skipped: network unavailable',
          error: error,
        );
        return const Right(SessionValidityResult.verificationUnknown);
      }
      logger.w(
        'Session validity check threw unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(
        UnexpectedFailure(
          'Session validity check failed: ${error.runtimeType}',
        ),
      );
    }
  }
}
