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
  Future<bool> requestPermission({bool allowOpenSettings = false});
  Future<bool> isLocationServiceEnabled();
}

@LazySingleton(as: LocationDataSource)
class LocationDataSourceImpl implements LocationDataSource {
  LocationDataSourceImpl(this._geolocatorClient);

  final GeolocatorClient _geolocatorClient;

  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
    timeLimit: Duration(seconds: 15),
  );

  /// Hard cap on the native reverse-geocoder. `placemarkFromCoordinates` has no
  /// built-in timeout and can hang indefinitely when the platform Geocoder is
  /// slow/unavailable — which would freeze the prayer-times screen on its
  /// loading spinner, since the load awaits it. On timeout we fall back to the
  /// offline approximation (country) or simply skip the location name.
  static const Duration _geocodingTimeout = Duration(seconds: 5);

  /// Dart-side backstop for the position fetch in case Geolocator's own
  /// [LocationSettings.timeLimit] does not fire on a given device.
  static const Duration _positionTimeout = Duration(seconds: 18);

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
        return _getLocationResultFromPosition(lastKnown);
      }
    }

    try {
      final Position position = await _geolocatorClient
          .getCurrentPosition(locationSettings: _locationSettings)
          .timeout(_positionTimeout);
      return _getLocationResultFromPosition(position);
    } catch (e) {
      final Position? lastKnown = await _geolocatorClient
          .getLastKnownPosition();
      if (lastKnown != null) {
        return _getLocationResultFromPosition(lastKnown);
      }

      if (e is TimeoutException) {
        return LocationResult.error(
          'Location request timed out. Please check your GPS signal.',
        );
      }

      return LocationResult.error('Failed to get current location: $e');
    }
  }

  @override
  Future<String?> getCountryCode(double latitude, double longitude) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(_geocodingTimeout);

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
  Future<bool> requestPermission({bool allowOpenSettings = false}) async {
    try {
      LocationPermission permission = await _geolocatorClient.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await _geolocatorClient.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        // Only jump to the system settings page on an explicit user action
        // ([allowOpenSettings] == true). During the passive prayer-times load
        // this would yank the user out to the App-info page and loop right back
        // here on resume — which read as a crash.
        if (allowOpenSettings) {
          await _geolocatorClient.openAppSettings();
        }
        return false;
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (_) {
      // Never let a platform/permission error cross the layer boundary.
      return false;
    }
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

  Future<LocationResult> _getLocationResultFromPosition(
    Position position,
  ) async {
    String? locationName;
    String? countryCode;

    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(_geocodingTimeout);

      if (placemarks.isNotEmpty) {
        final List<String> addressParts = [];

        bool isValidPart(String? part) {
          if (part == null || part.trim().isEmpty) return false;
          final trimmed = part.trim();
          if (trimmed.contains('Unnamed')) return false;
          // Filter out Google Plus Codes
          if (trimmed.contains('+') && !trimmed.contains(' ')) return false;
          // Filter out single character/number strings (like '25', '7a') that aren't fully descriptive
          if (RegExp(r'^[a-zA-Z0-9]{1,3}$').hasMatch(trimmed)) return false;
          return true;
        }

        String? thoroughfare,
            subLocality,
            street,
            name,
            locality,
            subAdmin,
            admin,
            country,
            isoCountryCode;

        for (final place in placemarks) {
          if (thoroughfare == null && isValidPart(place.thoroughfare)) {
            thoroughfare = place.thoroughfare!.trim();
          }
          if (subLocality == null && isValidPart(place.subLocality)) {
            subLocality = place.subLocality!.trim();
          }
          if (street == null && isValidPart(place.street)) {
            street = place.street!.trim();
          }
          if (name == null && isValidPart(place.name)) {
            name = place.name!.trim();
          }

          if (locality == null && isValidPart(place.locality)) {
            locality = place.locality!.trim();
          }
          if (subAdmin == null && isValidPart(place.subAdministrativeArea)) {
            subAdmin = place.subAdministrativeArea!.trim();
          }
          if (admin == null && isValidPart(place.administrativeArea)) {
            admin = place.administrativeArea!.trim();
          }
          if (country == null && isValidPart(place.country)) {
            country = place.country!.trim();
          }
          if (isoCountryCode == null && place.isoCountryCode != null) {
            isoCountryCode = place.isoCountryCode;
          }
        }

        // 1. Street-level accuracy
        if (thoroughfare != null) {
          addressParts.add(thoroughfare);
        } else if (subLocality != null) {
          addressParts.add(subLocality);
        } else if (street != null) {
          addressParts.add(street);
        } else if (name != null) {
          addressParts.add(name);
        }

        // 2. City-level accuracy
        if (locality != null && !addressParts.contains(locality)) {
          addressParts.add(locality);
        } else if (subAdmin != null && !addressParts.contains(subAdmin)) {
          addressParts.add(subAdmin);
        }

        if (addressParts.isNotEmpty) {
          locationName = addressParts.toSet().join('، ');
        } else {
          locationName = admin ?? country;
        }

        countryCode = isoCountryCode;
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
