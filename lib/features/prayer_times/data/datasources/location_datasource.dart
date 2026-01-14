import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

import '../../domain/repositories/prayer_times_repository.dart';
import '../services/geolocator_client.dart';

abstract class LocationDataSource {
  Future<LocationResult> getCurrentLocation();
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<bool> isLocationServiceEnabled();
}

@LazySingleton(as: LocationDataSource)
class LocationDataSourceImpl implements LocationDataSource {
  LocationDataSourceImpl(this._geolocatorClient);

  final GeolocatorClient _geolocatorClient;

  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.medium,
    timeLimit: Duration(seconds: 5),
  );

  @override
  Future<LocationResult> getCurrentLocation() async {
    final bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult.error('Location services are disabled');
    }

    final bool permissionGranted = await _ensurePermission();
    if (!permissionGranted) {
      return LocationResult.error('Location permission denied');
    }

    return _getLocationResult();
  }

  @override
  Future<bool> hasPermission() async {
    final LocationPermission permission = await _geolocatorClient
        .checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  @override
  Future<bool> requestPermission() async {
    LocationPermission permission = await _geolocatorClient.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await _geolocatorClient.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await _geolocatorClient.openAppSettings();
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return _geolocatorClient.isLocationServiceEnabled();
  }

  Future<bool> _ensurePermission() async {
    final bool hasPermissionGranted = await hasPermission();
    if (hasPermissionGranted) {
      return true;
    }

    return requestPermission();
  }

  Future<LocationResult> _getLocationResult() async {
    try {
      final Position position = await _geolocatorClient.getCurrentPosition(
        locationSettings: _locationSettings,
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      // Fallback to last known position on any error (including timeout)
      final Position? lastKnown = await _geolocatorClient
          .getLastKnownPosition();
      if (lastKnown != null) {
        return LocationResult(
          latitude: lastKnown.latitude,
          longitude: lastKnown.longitude,
        );
      }

      if (e is TimeoutException) {
        return LocationResult.error(
          'Location request timed out. Please check your GPS signal.',
        );
      }

      return LocationResult.error('Failed to get location: $e');
    }
  }
}
