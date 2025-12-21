import '../entities/qibla_direction_entity.dart';

abstract class QiblaRepository {
  /// Stream of Qibla direction updates
  Stream<QiblaDirectionEntity> getQiblaDirection();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled();

  /// Request location permissions
  Future<bool> requestLocationPermission();
}
