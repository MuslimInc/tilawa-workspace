import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
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
    } catch (_) {
      return const Right(SessionValidityResult.verificationUnknown);
    }
  }
}
