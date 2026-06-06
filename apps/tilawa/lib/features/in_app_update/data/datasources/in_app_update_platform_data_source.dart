import '../../domain/entities/in_app_update_availability.dart';

/// Platform bridge for Google Play in-app updates.
abstract class InAppUpdatePlatformDataSource {
  Future<bool> isSupported();

  Future<InAppUpdateAvailability> checkAvailability();

  Future<void> performImmediateUpdate();

  Future<bool> startFlexibleUpdate();

  Future<void> completeFlexibleUpdate();
}
