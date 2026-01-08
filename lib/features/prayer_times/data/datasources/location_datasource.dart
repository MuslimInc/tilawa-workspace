import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

import '../../domain/repositories/prayer_times_repository.dart';

abstract class LocationDataSource {
  Future<LocationResult> getCurrentLocation();
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<bool> isLocationServiceEnabled();
}

@LazySingleton(as: LocationDataSource)
class LocationDataSourceImpl implements LocationDataSource {
  @override
  Future<LocationResult> getCurrentLocation() async {
    try {
      final bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.error('Location services are disabled');
      }

      final bool hasPermissionGranted = await hasPermission();
      if (!hasPermissionGranted) {
        final bool granted = await requestPermission();
        if (!granted) {
          return LocationResult.error('Location permission denied');
        }
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      return LocationResult.error('Failed to get location: $e');
    }
  }

  @override
  Future<bool> hasPermission() async {
    final LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  @override
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }
}
