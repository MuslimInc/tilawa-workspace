import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/core/network/network_error_message.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/server_session_snapshot.dart';
import '../../domain/repositories/session_validity_repository.dart';

@LazySingleton(as: SessionValidityRepository)
class FirestoreSessionValidityRepository implements SessionValidityRepository {
  FirestoreSessionValidityRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<Either<Failure, ServerSessionSnapshot>> fetchServerSession(
    String userId,
  ) async {
    try {
      final snap = await _firestore.collection('users').doc(userId).get();
      final rawEpoch = snap.data()?['session']?['epoch'];
      final serverEpoch = rawEpoch is num ? rawEpoch.toInt() : 0;
      final rawActiveDeviceId = snap.data()?['session']?['activeDeviceId'];
      final serverActiveDeviceId = rawActiveDeviceId is String
          ? rawActiveDeviceId
          : '';
      return Right(
        ServerSessionSnapshot(
          epoch: serverEpoch,
          activeDeviceId: serverActiveDeviceId,
        ),
      );
    } on FirebaseException catch (error, stackTrace) {
      if (_isNetworkIssue(error)) {
        logger.d(
          'Session validity fetch skipped: network unavailable',
          error: error,
        );
        return const Left(ServerFailure(SessionValidityFailureKey.network));
      }
      logger.w(
        'Session validity fetch failed (${error.code})',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure('session_validity_check_${error.code}'));
    } on TimeoutException catch (error) {
      logger.d('Session validity fetch timed out', error: error);
      return const Left(ServerFailure(SessionValidityFailureKey.network));
    } catch (error, stackTrace) {
      if (isNetworkConnectivityErrorMessage(error.toString())) {
        logger.d(
          'Session validity fetch skipped: network unavailable',
          error: error,
        );
        return const Left(ServerFailure(SessionValidityFailureKey.network));
      }
      logger.w(
        'Session validity fetch threw unexpectedly',
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
