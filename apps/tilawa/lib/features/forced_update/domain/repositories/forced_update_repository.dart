import '../entities/forced_update_policy.dart';

/// Reads remote forced-update policy. Failures are handled fail-open upstream.
abstract class ForcedUpdateRepository {
  Future<ForcedUpdatePolicy> getPolicy();
}
