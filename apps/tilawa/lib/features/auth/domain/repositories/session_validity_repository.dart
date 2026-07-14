import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../entities/server_session_snapshot.dart';

/// Sentinel [Failure.message] for recoverable network/timeout while fetching
/// session. Callers map this to [SessionValidityResult.verificationUnknown].
abstract final class SessionValidityFailureKey {
  static const String network = 'session_validity_network';
}

/// Reads the authoritative session document for validity checks.
abstract class SessionValidityRepository {
  /// Fetches `session.epoch` / `session.activeDeviceId` for [userId].
  ///
  /// Network and timeout problems return
  /// [Left] with [SessionValidityFailureKey.network] (not a hard server error).
  Future<Either<Failure, ServerSessionSnapshot>> fetchServerSession(
    String userId,
  );
}
