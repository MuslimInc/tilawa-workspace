import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:qibla/qibla.dart';

class MockGeolocatorPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements GeolocatorPlatform {}

class FakePosition extends Fake implements Position {
  FakePosition({required this.fakeLatitude, required this.fakeLongitude});

  final double fakeLatitude;
  final double fakeLongitude;

  @override
  double get latitude => fakeLatitude;

  @override
  double get longitude => fakeLongitude;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('ml.medyas.qibla');
  final log = <MethodCall>[];

  setUpAll(() {
    registerFallbackValue(
      const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 10,
      ),
    );
  });

  setUp(() {
    log.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          log.add(methodCall);
          if (methodCall.method == 'androidSupportSensor') {
            return true;
          }
          return null;
        });

    GeolocatorPlatform.instance = MockGeolocatorPlatform();
    Qibla.instance = Qibla.internal();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'androidDeviceSensorSupport calls platform channel on Android',
    () async {
      final instance = Qibla.internal();
      instance.platformIsAndroid = true;
      Qibla.instance = instance;

      final bool? result = await Qibla.androidDeviceSensorSupport();

      expect(log, hasLength(1));
      expect(log.single.method, 'androidSupportSensor');
      expect(result, isTrue);
    },
  );

  test('requestPermissions calls Geolocator.requestPermission', () async {
    final mockGeolocator =
        GeolocatorPlatform.instance as MockGeolocatorPlatform;
    when(
      mockGeolocator.requestPermission,
    ).thenAnswer((_) async => LocationPermission.whileInUse);

    final LocationPermission result = await Qibla.requestPermissions();

    expect(result, LocationPermission.whileInUse);
    verify(mockGeolocator.requestPermission).called(1);
  });

  test('checkLocationStatus calls Geolocator methods', () async {
    final mockGeolocator =
        GeolocatorPlatform.instance as MockGeolocatorPlatform;
    when(
      mockGeolocator.checkPermission,
    ).thenAnswer((_) async => LocationPermission.denied);
    when(
      mockGeolocator.isLocationServiceEnabled,
    ).thenAnswer((_) async => false);

    final LocationStatus result = await Qibla.checkLocationStatus();

    expect(result.enabled, isFalse);
    expect(result.status, LocationPermission.denied);
    verify(mockGeolocator.checkPermission).called(1);
    verify(mockGeolocator.isLocationServiceEnabled).called(1);
  });

  group('locationStream initial fix strategy', () {
    test('uses last known position first when available', () async {
      final instance = Qibla.internal();
      final mockGeolocator =
          GeolocatorPlatform.instance as MockGeolocatorPlatform;

      final lastKnown = FakePosition(fakeLatitude: 24.7, fakeLongitude: 46.6);
      when(
        mockGeolocator.getLastKnownPosition,
      ).thenAnswer((_) async => lastKnown);

      final Position result = await instance.locationStream.first;

      expect(result.latitude, 24.7);
      expect(result.longitude, 46.6);
      verify(mockGeolocator.getLastKnownPosition).called(1);
      verifyNever(
        () => mockGeolocator.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      );
    });

    test('uses quick current position when no last known position', () async {
      final instance = Qibla.internal();
      final mockGeolocator =
          GeolocatorPlatform.instance as MockGeolocatorPlatform;

      final quickFix = FakePosition(fakeLatitude: 21.4, fakeLongitude: 39.8);
      when(
        mockGeolocator.getLastKnownPosition,
      ).thenAnswer((_) async => null);
      when(
        () => mockGeolocator.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenAnswer((_) async => quickFix);

      final Position result = await instance.locationStream.first;

      expect(result.latitude, 21.4);
      expect(result.longitude, 39.8);
      verify(mockGeolocator.getLastKnownPosition).called(1);
      verify(
        () => mockGeolocator.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).called(1);
      verifyNever(
        () => mockGeolocator.getPositionStream(
          locationSettings: any(named: 'locationSettings'),
        ),
      );
    });

    test('falls back to stream when quick fix fails', () async {
      final instance = Qibla.internal();
      final mockGeolocator =
          GeolocatorPlatform.instance as MockGeolocatorPlatform;

      final streamFix = FakePosition(fakeLatitude: 40.7, fakeLongitude: -74.0);
      when(
        mockGeolocator.getLastKnownPosition,
      ).thenAnswer((_) async => null);
      when(
        () => mockGeolocator.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenThrow(Exception('quick fix failed'));
      when(
        () => mockGeolocator.getPositionStream(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenAnswer((_) => Stream<Position>.value(streamFix));

      final Position result = await instance.locationStream.first;

      expect(result.latitude, 40.7);
      expect(result.longitude, -74.0);
      verify(mockGeolocator.getLastKnownPosition).called(1);
      verify(
        () => mockGeolocator.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).called(1);
      verify(
        () => mockGeolocator.getPositionStream(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).called(1);
    });
  });

  test('internal getters are accessible', () {
    final instance = Qibla.internal();
    expect(() => instance.locationStream, returnsNormally);
    expect(() => instance.compassEvents, returnsNormally);
  });
}
