import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/services/token_sync_cache.dart';

@injectable
class CheckSessionValidityUseCase {
  CheckSessionValidityUseCase(this._firestore, this._tokenSyncCache);

  final FirebaseFirestore _firestore;
  final TokenSyncCache _tokenSyncCache;

  /// Returns `true` when local epoch matches server (session still valid).
  Future<Either<Failure, bool>> call(String userId) async {
    try {
      final localEpoch = await _tokenSyncCache.getSessionEpoch() ?? 0;
      final snap = await _firestore.collection('users').doc(userId).get();
      final rawEpoch = snap.data()?['session']?['epoch'];
      final serverEpoch = rawEpoch is num ? rawEpoch.toInt() : 0;
      return Right(localEpoch == serverEpoch);
    } catch (error) {
      return Left(Failure.unexpectedError(error.toString()));
    }
  }
}
