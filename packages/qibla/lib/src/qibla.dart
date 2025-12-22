import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass_v2/flutter_compass_v2.dart';
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
    _qiblaStream ??= _merge<CompassEvent, Position>(
      compassEvents,
      locationStream.transform(
        StreamTransformer<Position, Position>.fromHandlers(
          handleData: (Position position, EventSink<Position> sink) {
            sink.add(position);
            sink.close();
          },
        ),
      ),
    );

    return _qiblaStream!;
  }

  /// For testing purposes, we can override these streams
  Stream<CompassEvent> get compassEvents => FlutterCompass.events!;

  Stream<Position> get locationStream => Geolocator.getPositionStream();

  Stream<QiblaDirection> _merge<A, B>(Stream<A> streamA, Stream<B> streamB) =>
      streamA.combineLatest<B, QiblaDirection>(streamB, (dir, pos) {
        final position = pos as Position;
        final event = dir as CompassEvent;

        // Calculate the Qibla offset to North
        final double offSet = Utils.getOffsetFromNorth(
          position.latitude,
          position.longitude,
        );

        // Adjust Qibla direction based on North direction
        final double qibla = (event.heading ?? 0.0) + (360 - offSet);

        return QiblaDirection(qibla, event.heading ?? 0.0, offSet);
      });

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
  const QiblaDirection(this.qibla, this.direction, this.offset);
  final double qibla;
  final double direction;
  final double offset;
}
