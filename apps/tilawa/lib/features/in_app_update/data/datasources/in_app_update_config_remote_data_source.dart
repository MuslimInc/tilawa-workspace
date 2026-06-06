import '../../domain/entities/in_app_update_policy.dart';

/// Reads remote in-app update policy from Firestore.
abstract class InAppUpdateConfigRemoteDataSource {
  Future<InAppUpdatePolicy> getPolicy();
}
