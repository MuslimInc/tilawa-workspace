import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/core/network/network_error_message.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../entities/session_validity_result.dart';
import '../../domain/services/token_sync_cache.dart';

@injectable
class CheckSessionValidityUseCase {
  CheckSessionValidityUseCase(this._firestore, this._tokenSyncCache);

  final FirebaseFirestore _firestore;
  final TokenSyncCache _tokenSyncCache;

  /// Returns [SessionValidityResult.valid] when local session matches server.
  Future<Either<Failure, SessionValidityResult>> call(String userId) async {
    try {
      final localEpoch = await _tokenSyncCache.getSessionEpoch() ?? 0;
      final localActiveDeviceId = await _tokenSyncCache.getActiveDeviceId();
      final snap = await _firestore.collection('users').doc(userId).get();
      final rawEpoch = snap.data()?['session']?['epoch'];
      final serverEpoch = rawEpoch is num ? rawEpoch.toInt() : 0;
      final rawActiveDeviceId = snap.data()?['session']?['activeDeviceId'];
      final serverActiveDeviceId = rawActiveDeviceId is String
          ? rawActiveDeviceId
          : '';
      final isValid =
          localEpoch == serverEpoch &&
          localActiveDeviceId != null &&
          localActiveDeviceId == serverActiveDeviceId;
      return Right(
        isValid ? SessionValidityResult.valid : SessionValidityResult.stale,
      );
    } on FirebaseException catch (error, stackTrace) {
      if (_isNetworkIssue(error)) {
        logger.d(
          'Session validity check skipped: network unavailable',
          error: error,
        );
        return const Right(SessionValidityResult.verificationUnknown);
      }
      logger.w(
        'Session validity check failed (${error.code})',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure('session_validity_check_${error.code}'));
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

  bool _isNetworkIssue(FirebaseException error) {
    return error.code == 'unavailable' ||
        error.code == 'deadline-exceeded' ||
        isNetworkConnectivityErrorMessage(error.message ?? '');
  }
}
