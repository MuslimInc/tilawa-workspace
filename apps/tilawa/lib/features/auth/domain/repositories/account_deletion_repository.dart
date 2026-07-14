import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/errors/failures.dart';

/// Soft-deletes the signed-in account via backend callable.
abstract class AccountDeletionRepository {
  /// Requests self-service deletion. Maps callable/network errors to [Failure].
  Future<Either<Failure, void>> requestSelfAccountDeletion({
    required String reason,
    required String confirmEmail,
  });
}
