import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

abstract class GeolocatorClient {
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<void> openAppSettings();
  Future<Position> getCurrentPosition({LocationSettings? locationSettings});
  Future<Position?> getLastKnownPosition();
}

@LazySingleton(as: GeolocatorClient)
class GeolocatorClientImpl implements GeolocatorClient {
  @override
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    return Geolocator.getCurrentPosition(locationSettings: locationSettings);
  }

  @override
  Future<Position?> getLastKnownPosition() => Geolocator.getLastKnownPosition();
}
