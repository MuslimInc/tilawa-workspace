import '../entities/in_app_update_availability.dart';
import '../entities/in_app_update_policy.dart';

/// Domain contract for remote policy and Play in-app update operations.
abstract class InAppUpdateRepository {
  Future<bool> isSupported();

  Future<InAppUpdatePolicy> getPolicy();

  Future<InAppUpdateAvailability> checkAvailability();

  Future<void> performImmediateUpdate();

  Future<bool> startFlexibleUpdate();

  Future<void> completeFlexibleUpdate();
}
