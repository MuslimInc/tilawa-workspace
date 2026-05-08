import 'dart:async';
import 'dart:io';

import 'package:compass/flutter_compass.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stream_transform/stream_transform.dart';

import 'utils.dart';

/// [Qibla] is a singleton class that provides assess to compass events,
/// check for sensor support in Android
/// Get current  location
/// Get Qibla direction
class Qibla {
  factory Qibla() => instance;

  @visibleForTesting
  Qibla.internal();
  static Qibla instance = Qibla.internal();

  static const _channel = MethodChannel('ml.medyas.qibla');
  static const Duration _quickFixTimeout = Duration(seconds: 3);
  static const Duration _streamFixTimeout = Duration(seconds: 7);
  static const LocationSettings _quickLocationSettings = LocationSettings(
    accuracy: LocationAccuracy.medium,
    distanceFilter: 10,
  );
  static const LocationSettings _streamLocationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );

  Stream<QiblaDirection>? _qiblaStream;

  /// Check Android device sensor support
  static Future<bool?> androidDeviceSensorSupport() =>
      instance.checkAndroidDeviceSensorSupport();

  /// Request Location permission, return GeolocationStatus object
  static Future<LocationPermission> requestPermissions() =>
      instance.requestLocationPermission();

  /// get location status: GPS enabled and the permission status with GeolocationStatus
  static Future<LocationStatus> checkLocationStatus() =>
      instance.getLocationStatus();

  /// Provides a stream of Map with current compass and Qibla direction
  /// {"qibla": QIBLA, "direction": DIRECTION}
  /// Direction varies from 0-360, 0 being north.
  /// Qibla varies from 0-360, offset from direction(North)
  static Stream<QiblaDirection> get qiblaStream => instance.getQiblaStream();

  /* Instance methods that can be overridden for testing */

  @visibleForTesting
  bool platformIsAndroid = Platform.isAndroid;

  Future<bool?> checkAndroidDeviceSensorSupport() async {
    if (platformIsAndroid) {
      return _channel.invokeMethod('androidSupportSensor');
    } else {
      return true;
    }
  }

  Future<LocationPermission> requestLocationPermission() =>
      Geolocator.requestPermission();

  Future<LocationStatus> getLocationStatus() async {
    final LocationPermission status = await Geolocator.checkPermission();
    final bool enabled = await Geolocator.isLocationServiceEnabled();
    return LocationStatus(enabled, status);
  }

  Stream<QiblaDirection> getQiblaStream() {
    _qiblaStream ??= _merge(compassEvents, locationStream.take(1));

    return _qiblaStream!;
  }

  /// For testing purposes, we can override these streams
  Stream<CompassEvent> get compassEvents => FlutterCompass.events!;

  Stream<Position> get locationStream => _initialLocationStream();

  Stream<Position> _initialLocationStream() async* {
    final Position? lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) {
      yield lastKnown;
      return;
    }

    try {
      final Position quickFix = await Geolocator.getCurrentPosition(
        locationSettings: _quickLocationSettings,
      ).timeout(_quickFixTimeout);
      yield quickFix;
      return;
    } catch (_) {
      // Fall through to the stream-based GPS fix.
    }

    yield* Geolocator.getPositionStream(
          locationSettings: _streamLocationSettings,
        )
        .take(1)
        .timeout(
          _streamFixTimeout,
          onTimeout: (EventSink<Position> sink) => sink.close(),
        );
  }

  Stream<QiblaDirection> _merge(
    Stream<CompassEvent> compassStream,
    Stream<Position> locationStream,
  ) {
    final Stream<double> offsetStream = locationStream.map((position) {
      return Utils.getOffsetFromNorth(position.latitude, position.longitude);
    });

    return compassStream.combineLatest<double, QiblaDirection>(offsetStream, (
      event,
      offSet,
    ) {
      // Adjust Qibla direction based on North direction
      final double heading = _normalizeAngle(event.heading ?? 0.0);
      final double qibla = _normalizeAngle(heading + (360 - offSet));

      return QiblaDirection(qibla, heading, offSet, accuracy: event.accuracy);
    });
  }

  double _normalizeAngle(double value) {
    return (value % 360 + 360) % 360;
  }

  /// Close compass stream, and set Qibla stream to null
  void dispose() {
    _qiblaStream = null;
  }
}

/// Location Status class, contains the GPS status(Enabled or not) and GeolocationStatus
class LocationStatus {
  const LocationStatus(this.enabled, this.status);
  final bool enabled;
  final LocationPermission status;
}

/// Containing Qibla, Direction and offset
class QiblaDirection {
  const QiblaDirection(
    this.qibla,
    this.direction,
    this.offset, {
    this.accuracy,
  });
  final double qibla;
  final double direction;
  final double offset;
  final double? accuracy;
}
