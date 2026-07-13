import 'dart:async';

import 'package:compass/flutter_compass.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qibla/qibla.dart';

class MockFlutterQibla extends Mock implements Qibla {}

class MockCompassEvent extends Mock implements CompassEvent {}

class TestableFlutterQibla extends Qibla {
  TestableFlutterQibla(this.compassStream, this.positionStream)
    : super.internal();
  final Stream<CompassEvent> compassStream;
  final Stream<Position> positionStream;

  @override
  Stream<CompassEvent> get compassEvents => compassStream;

  @override
  Stream<Position> get locationStream => positionStream;

  @override
  Future<LocationPermission> requestLocationPermission() =>
      Future.value(LocationPermission.always);

  @override
  Future<LocationStatus> getLocationStatus() =>
      Future.value(const LocationStatus(true, LocationPermission.always));
}

class FakePosition extends Fake implements Position {
  @override
  double get latitude => 51.5074;
  @override
  double get longitude => -0.1278;
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakePosition());
  });

  group('FlutterQibla', () {
    test('singleton returns same instance', () {
      expect(Qibla(), isNotNull);
      expect(Qibla(), same(Qibla()));
    });

    test('setInstance updates the instance', () {
      final mock = MockFlutterQibla();
      final original = Qibla();

      Qibla.instance = mock;
      expect(Qibla(), same(mock));

      // Cleanup
      Qibla.instance = original;
    });

    test('requestPermissions calls instance method', () async {
      final mock = MockFlutterQibla();
      Qibla.instance = mock;

      when(
        mock.requestLocationPermission,
      ).thenAnswer((_) async => LocationPermission.always);

      final LocationPermission result = await Qibla.requestPermissions();
      expect(result, LocationPermission.always);
      verify(mock.requestLocationPermission).called(1);
    });

    test('checkLocationStatus calls instance method', () async {
      final mock = MockFlutterQibla();
      Qibla.instance = mock;

      when(mock.getLocationStatus).thenAnswer(
        (_) async => const LocationStatus(true, LocationPermission.whileInUse),
      );

      final LocationStatus result = await Qibla.checkLocationStatus();
      expect(result.enabled, isTrue);
      expect(result.status, LocationPermission.whileInUse);
      verify(mock.getLocationStatus).called(1);
    });

    test('qiblaStream merges compass and location correctly', () async {
      final compassController = StreamController<CompassEvent>();
      final locationController = StreamController<Position>();

      final testable = TestableFlutterQibla(
        compassController.stream,
        locationController.stream,
      );

      Qibla.instance = testable;

      final Stream<QiblaDirection> stream = Qibla.qiblaStream;

      final results = <QiblaDirection>[];
      final StreamSubscription<QiblaDirection> subscription = stream.listen(
        results.add,
      );

      // London coordinates
      final pos = FakePosition();

      final event1 = MockCompassEvent();
      when(() => event1.heading).thenReturn(0.0);
      when(() => event1.accuracy).thenReturn(45.0);

      locationController.add(pos);
      compassController.add(event1); // North

      await Future<void>.delayed(Duration.zero);

      expect(results.length, 1);
      // Qibla for London is ~119. So offset from North(0) is ~119.
      // Qibla in results is heading + (360 - offset) = 0 + (360 - 119) = 241
      expect(results[0].qibla, closeTo(241, 1));
      expect(results[0].direction, 0.0);
      expect(results[0].offset, closeTo(119, 1));
      expect(results[0].accuracy, 45.0);

      // Update heading to 90 (East)
      final event2 = MockCompassEvent();
      when(() => event2.heading).thenReturn(90.0);
      when(() => event2.accuracy).thenReturn(15.0);

      compassController.add(event2);
      await Future<void>.delayed(Duration.zero);

      expect(results.length, 2);
      // qibla = 90 + (360 - 119) = 90 + 241 = 331
      expect(results[1].qibla, closeTo(331, 1));
      expect(results[1].accuracy, 15.0);

      await subscription.cancel();
      await compassController.close();
      await locationController.close();
    });

    test(
      'androidDeviceSensorSupport returns true on non-Android (real implementation)',
      () async {
        // Use TestableFlutterQibla which uses the real checkAndroidDeviceSensorSupport
        final testable = TestableFlutterQibla(
          const Stream.empty(),
          const Stream.empty(),
        );
        Qibla.instance = testable;

        // On macOS/iOS this should be true.
        // If we are strictly on a host machine that is not Android.
        final bool? result = await Qibla.androidDeviceSensorSupport();
        expect(result, isTrue);
      },
    );

    test('dispose resets the qibla stream', () {
      final compassController = StreamController<CompassEvent>();
      final locationController = StreamController<Position>();

      final testable = TestableFlutterQibla(
        compassController.stream,
        locationController.stream,
      );
      Qibla.instance = testable;

      final Stream<QiblaDirection> stream1 = Qibla.qiblaStream;
      final Stream<QiblaDirection> stream2 = Qibla.qiblaStream;

      // Should be the same cached instance
      expect(stream1, same(stream2));

      Qibla().dispose();

      final Stream<QiblaDirection> stream3 = Qibla.qiblaStream;

      // Should be a new instance after dispose
      expect(stream3, isNot(same(stream1)));

      compassController.close();
      locationController.close();
    });
  });
}
