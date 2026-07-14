import '../../domain/entities/forced_update_policy.dart';

/// Reads remote forced-update policy from Firestore.
abstract class ForcedUpdateConfigRemoteDataSource {
  Future<ForcedUpdatePolicy> getPolicy();
}
