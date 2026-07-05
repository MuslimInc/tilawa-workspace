import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart'
    as platform;
import 'package:geolocator/geolocator.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:tilawa/features/prayer_times/data/datasources/location_datasource.dart';
import 'package:tilawa/features/prayer_times/data/services/geolocator_client.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';

import 'location_datasource_test.mocks.dart';

class MockGeocoding extends platform.Geocoding {
  MockGeocoding(super.params) : super.implementation();

  List<Placemark> mockPlacemarks = [];
  bool shouldThrow = false;

  @override
  Future<List<Placemark>> placemarkFromCoordinates(
    double latitude,
    double longitude, {
    Locale? locale,
  }) async {
    if (shouldThrow) throw Exception('Geocoding error');
    return mockPlacemarks;
  }
}

class MockGeocodingPlatformFactory extends platform.GeocodingPlatformFactory
    with MockPlatformInterfaceMixin {
  MockGeocoding? currentGeocoding;
  List<Placemark> mockPlacemarks = [];
  bool shouldThrow = false;

  @override
  platform.Geocoding createGeocoding(platform.GeocodingCreationParams params) {
    final geocoding = MockGeocoding(params);
    geocoding.mockPlacemarks = mockPlacemarks;
    geocoding.shouldThrow = shouldThrow;
    currentGeocoding = geocoding;
    return geocoding;
  }
}

@GenerateMocks([GeolocatorClient])
void main() {
  late LocationDataSourceImpl dataSource;
  late MockGeolocatorClient mockGeolocatorClient;
  late MockGeocodingPlatformFactory mockGeocodingPlatformFactory;

  setUp(() {
    mockGeocodingPlatformFactory = MockGeocodingPlatformFactory();
    platform.GeocodingPlatformFactory.instance = mockGeocodingPlatformFactory;
    mockGeolocatorClient = MockGeolocatorClient();
    dataSource = LocationDataSourceImpl(mockGeolocatorClient);
  });

  group('LocationDataSource', () {
    final tPosition = Position(
      longitude: 10.0,
      latitude: 10.0,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );

    group('getCurrentLocation', () {
      test(
        'should return cached location when available and forceRefresh is false',
        () async {
          when(
            mockGeolocatorClient.isLocationServiceEnabled(),
          ).thenAnswer((_) async => true);
          when(
            mockGeolocatorClient.checkPermission(),
          ).thenAnswer((_) async => LocationPermission.whileInUse);
          when(
            mockGeolocatorClient.getLastKnownPosition(),
          ).thenAnswer((_) async => tPosition);

          mockGeocodingPlatformFactory.mockPlacemarks = [
            Placemark(
              isoCountryCode: 'EG',
              locality: 'Cairo',
              name: 'Downtown',
            ),
          ];

          final LocationResult result = await dataSource.getCurrentLocation();

          expect(result.latitude, tPosition.latitude);
          expect(result.longitude, tPosition.longitude);
          expect(result.countryCode, 'EG');
          expect(result.locationName, 'Downtown, Cairo');
          verifyNever(
            mockGeolocatorClient.getCurrentPosition(
              locationSettings: anyNamed('locationSettings'),
            ),
          );
        },
      );

      test('should fetch fresh location when forceRefresh is true', () async {
        when(
          mockGeolocatorClient.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockGeolocatorClient.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);
        when(
          mockGeolocatorClient.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).thenAnswer((_) async => tPosition);

        mockGeocodingPlatformFactory.mockPlacemarks = [
          Placemark(
            isoCountryCode: 'US',
            locality: 'New York',
            name: 'Times Square',
          ),
        ];

        final LocationResult result = await dataSource.getCurrentLocation(
          forceRefresh: true,
        );

        expect(result.latitude, tPosition.latitude);
        expect(result.longitude, tPosition.longitude);
        expect(result.countryCode, 'US');
        expect(result.locationName, 'Times Square, New York');
        verify(
          mockGeolocatorClient.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).called(1);
      });

      test(
        'should return location with fallback country if geocoding fails',
        () async {
          when(
            mockGeolocatorClient.isLocationServiceEnabled(),
          ).thenAnswer((_) async => true);
          when(
            mockGeolocatorClient.checkPermission(),
          ).thenAnswer((_) async => LocationPermission.whileInUse);
          when(
            mockGeolocatorClient.getCurrentPosition(
              locationSettings: anyNamed('locationSettings'),
            ),
          ).thenAnswer((_) async => tPosition);

          mockGeocodingPlatformFactory.shouldThrow = true;

          final LocationResult result = await dataSource.getCurrentLocation(
            forceRefresh: true,
          );

          expect(result.latitude, tPosition.latitude);
          expect(result.longitude, tPosition.longitude);
          // Fallback for 10.0, 10.0 is null
          expect(result.countryCode, null);
        },
      );

      test('should return error when location service is disabled', () async {
        when(
          mockGeolocatorClient.isLocationServiceEnabled(),
        ).thenAnswer((_) async => false);
        final LocationResult result = await dataSource.getCurrentLocation();
        expect(result.error, 'Location services are disabled');
      });

      test(
        'should return error when permission is denied and request denied',
        () async {
          when(
            mockGeolocatorClient.isLocationServiceEnabled(),
          ).thenAnswer((_) async => true);
          when(
            mockGeolocatorClient.checkPermission(),
          ).thenAnswer((_) async => LocationPermission.denied);
          when(
            mockGeolocatorClient.requestPermission(),
          ).thenAnswer((_) async => LocationPermission.denied);

          final LocationResult result = await dataSource.getCurrentLocation();
          expect(result.error, 'Location permission denied');
        },
      );

      test(
        'falls back to last known position on exception (forceRefresh=true)',
        () async {
          when(
            mockGeolocatorClient.isLocationServiceEnabled(),
          ).thenAnswer((_) async => true);
          when(
            mockGeolocatorClient.checkPermission(),
          ).thenAnswer((_) async => LocationPermission.whileInUse);
          when(
            mockGeolocatorClient.getCurrentPosition(
              locationSettings: anyNamed('locationSettings'),
            ),
          ).thenThrow(Exception('Error'));
          when(
            mockGeolocatorClient.getLastKnownPosition(),
          ).thenAnswer((_) async => tPosition);

          final LocationResult result = await dataSource.getCurrentLocation(
            forceRefresh: true,
          );
          expect(result.latitude, tPosition.latitude);
        },
      );

      test('returns error on timeout if no last known position', () async {
        when(
          mockGeolocatorClient.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockGeolocatorClient.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);
        when(
          mockGeolocatorClient.getLastKnownPosition(),
        ).thenAnswer((_) async => null);
        when(
          mockGeolocatorClient.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).thenThrow(TimeoutException('Timeout'));

        final LocationResult result = await dataSource.getCurrentLocation();
        expect(result.error, contains('timed out'));
      });

      test('falls back to last known position on timeout', () async {
        var lastKnownCalls = 0;
        when(
          mockGeolocatorClient.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockGeolocatorClient.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);
        when(mockGeolocatorClient.getLastKnownPosition()).thenAnswer((_) async {
          lastKnownCalls++;
          return lastKnownCalls == 1 ? null : tPosition;
        });
        when(
          mockGeolocatorClient.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).thenThrow(TimeoutException('Timeout'));

        final LocationResult result = await dataSource.getCurrentLocation();
        expect(result.latitude, tPosition.latitude);
      });
    });

    group('getLocationName', () {
      test('returns name using placemarks correctly', () async {
        mockGeocodingPlatformFactory.mockPlacemarks = [
          Placemark(
            thoroughfare: 'Main St',
            locality: 'New York',
          ),
        ];

        final result = await dataSource.getLocationName(
          40.7,
          -74.0,
          localeIdentifier: 'en',
        );
        expect(result, 'Main St, New York');
      });

      test('returns null if geocoding fails', () async {
        mockGeocodingPlatformFactory.shouldThrow = true;
        final result = await dataSource.getLocationName(
          40.7,
          -74.0,
          localeIdentifier: 'en',
        );
        expect(result, isNull);
      });
    });

    group('requestPermission', () {
      test('returns true when permission explicitly granted', () async {
        when(
          mockGeolocatorClient.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.denied);
        when(
          mockGeolocatorClient.requestPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);

        final bool result = await dataSource.requestPermission();
        expect(result, true);
      });

      test(
        'denied forever returns false without opening settings by default',
        () async {
          when(
            mockGeolocatorClient.checkPermission(),
          ).thenAnswer((_) async => LocationPermission.denied);
          when(
            mockGeolocatorClient.requestPermission(),
          ).thenAnswer((_) async => LocationPermission.deniedForever);

          final bool result = await dataSource.requestPermission();
          expect(result, false);
          verifyNever(mockGeolocatorClient.openAppSettings());
        },
      );

      test(
        'denied forever opens settings when allowOpenSettings is true',
        () async {
          when(
            mockGeolocatorClient.checkPermission(),
          ).thenAnswer((_) async => LocationPermission.denied);
          when(
            mockGeolocatorClient.requestPermission(),
          ).thenAnswer((_) async => LocationPermission.deniedForever);
          when(mockGeolocatorClient.openAppSettings()).thenAnswer((_) async {});

          final bool result = await dataSource.requestPermission(
            allowOpenSettings: true,
          );
          expect(result, false);
          verify(mockGeolocatorClient.openAppSettings()).called(1);
        },
      );

      test('returns false on exception', () async {
        when(
          mockGeolocatorClient.checkPermission(),
        ).thenThrow(Exception('test'));
        final bool result = await dataSource.requestPermission();
        expect(result, false);
      });
    });

    group('hasPermission', () {
      test('returns true if whileInUse', () async {
        when(
          mockGeolocatorClient.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);
        final bool result = await dataSource.hasPermission();
        expect(result, true);
      });
    });

    group('isLocationServiceEnabled', () {
      test('delegates to client', () async {
        when(
          mockGeolocatorClient.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        final bool result = await dataSource.isLocationServiceEnabled();
        expect(result, true);
      });
    });

    group('getCountryCode', () {
      test('should return code from placemark if available', () async {
        mockGeocodingPlatformFactory.mockPlacemarks = [
          Placemark(isoCountryCode: 'SA'),
        ];

        final result = await dataSource.getCountryCode(24.7136, 46.6753);
        expect(result, 'SA');
      });

      test(
        'should fallback to EG for coordinates in Egypt when geocoding fails',
        () async {
          mockGeocodingPlatformFactory.shouldThrow = true;
          final result = await dataSource.getCountryCode(
            30.0444,
            31.2357,
          ); // Cairo
          expect(result, 'EG');
        },
      );

      test(
        'should fallback to SA for coordinates in Saudi Arabia when geocoding fails',
        () async {
          mockGeocodingPlatformFactory.shouldThrow = true;
          final result = await dataSource.getCountryCode(
            24.7136,
            46.6753,
          ); // Riyadh
          expect(result, 'SA');
        },
      );

      test(
        'should fallback to TR for coordinates in Turkey when geocoding fails',
        () async {
          mockGeocodingPlatformFactory.shouldThrow = true;
          final result = await dataSource.getCountryCode(
            39.9208,
            32.8541,
          ); // Ankara
          expect(result, 'TR');
        },
      );

      test(
        'should fallback to PK for coordinates in Pakistan when geocoding fails',
        () async {
          mockGeocodingPlatformFactory.shouldThrow = true;
          final result = await dataSource.getCountryCode(
            30.3753,
            69.3451,
          ); // Pakistan
          expect(result, 'PK');
        },
      );

      test(
        'should return null for unknown coordinates when geocoding fails',
        () async {
          mockGeocodingPlatformFactory.shouldThrow = true;
          final result = await dataSource.getCountryCode(0.0, 0.0); // Ocean
          expect(result, null);
        },
      );
    });
  });
}
