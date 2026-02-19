import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

import '../../domain/repositories/prayer_times_repository.dart';
import '../services/geolocator_client.dart';

abstract class LocationDataSource {
  Future<LocationResult> getCurrentLocation({bool forceRefresh = false});
  Future<String?> getCountryCode(double latitude, double longitude);
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<bool> isLocationServiceEnabled();
}

@LazySingleton(as: LocationDataSource)
class LocationDataSourceImpl implements LocationDataSource {
  LocationDataSourceImpl(this._geolocatorClient);

  final GeolocatorClient _geolocatorClient;

  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );

  @override
  Future<LocationResult> getCurrentLocation({bool forceRefresh = false}) async {
    final bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult.error('Location services are disabled');
    }

    final bool permissionGranted = await _ensurePermission();
    if (!permissionGranted) {
      return LocationResult.error('Location permission denied');
    }

    if (!forceRefresh) {
      final Position? lastKnown = await _geolocatorClient
          .getLastKnownPosition();
      if (lastKnown != null) {
        return LocationResult(
          latitude: lastKnown.latitude,
          longitude: lastKnown.longitude,
        );
      }
    }

    return _getLocationResult();
  }

  @override
  Future<String?> getCountryCode(double latitude, double longitude) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        final code = placemarks.first.isoCountryCode;
        if (code != null && code.isNotEmpty) {
          return code;
        }
      }
    } catch (e) {
      // Ignore geocoding errors
    }

    // Fallback detection
    return _approximateCountryCode(latitude, longitude);
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

      String? locationName;
      String? countryCode;

      try {
        final List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final Placemark place = placemarks.first;
          locationName = place.locality ?? place.subAdministrativeArea;
          countryCode = place.isoCountryCode;
        }
      } catch (e) {
        // Ignore geocoding errors, just return coordinates
      }

      // Fallback if geocoding fails or returns empty
      if (countryCode == null || countryCode.isEmpty) {
        countryCode = _approximateCountryCode(
          position.latitude,
          position.longitude,
        );
      }

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        locationName: locationName,
        countryCode: countryCode,
      );
    } catch (e) {
      if (e is TimeoutException) {
        return LocationResult.error(
          'Location request timed out. Please check your GPS signal.',
        );
      }

      // Fallback to last known position on any error
      final Position? lastKnown = await _geolocatorClient
          .getLastKnownPosition();
      if (lastKnown != null) {
        return LocationResult(
          latitude: lastKnown.latitude,
          longitude: lastKnown.longitude,
        );
      }

      return LocationResult.error('Failed to get location: $e');
    }
  }

  String? _approximateCountryCode(double latitude, double longitude) {
    // Egypt Bounding Box (Rough approximation)
    if (latitude >= 22.0 &&
        latitude <= 32.0 &&
        longitude >= 24.5 &&
        longitude <= 37.0) {
      return 'EG';
    }
    // Saudi Arabia
    if (latitude >= 16.0 &&
        latitude <= 32.5 &&
        longitude >= 34.0 &&
        longitude <= 56.0) {
      // Exclude Egypt overlap (if any - unlikely/minimal)
      if (!(latitude >= 22.0 &&
          latitude <= 32.0 &&
          longitude >= 24.5 &&
          longitude <= 37.0)) {
        return 'SA';
      }
    }
    // Turkey
    if (latitude >= 35.0 &&
        latitude <= 42.0 &&
        longitude >= 25.0 &&
        longitude <= 45.0) {
      return 'TR';
    }
    // Pakistan
    if (latitude >= 23.0 &&
        latitude <= 37.0 &&
        longitude >= 60.0 &&
        longitude <= 78.0) {
      return 'PK';
    }

    return null;
  }
}
