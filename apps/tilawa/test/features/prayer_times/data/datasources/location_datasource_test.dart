import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/prayer_times/data/datasources/location_datasource.dart';
import 'package:tilawa/features/prayer_times/data/services/geolocator_client.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';

import 'location_datasource_test.mocks.dart';

@GenerateMocks([GeolocatorClient])
void main() {
  late LocationDataSourceImpl dataSource;
  late MockGeolocatorClient mockGeolocatorClient;

  setUp(() {
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
          // Arrange
          when(
            mockGeolocatorClient.isLocationServiceEnabled(),
          ).thenAnswer((_) async => true);
          when(
            mockGeolocatorClient.checkPermission(),
          ).thenAnswer((_) async => LocationPermission.whileInUse);
          when(
            mockGeolocatorClient.getLastKnownPosition(),
          ).thenAnswer((_) async => tPosition);

          // Act
          final LocationResult result = await dataSource.getCurrentLocation();

          // Assert
          expect(result.latitude, tPosition.latitude);
          expect(result.longitude, tPosition.longitude);
          // Verify getCurrentPosition was NOT called
          verifyNever(
            mockGeolocatorClient.getCurrentPosition(
              locationSettings: anyNamed('locationSettings'),
            ),
          );
        },
      );

      test('should fetch fresh location when forceRefresh is true', () async {
        // Arrange
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

        // Act
        final LocationResult result = await dataSource.getCurrentLocation(
          forceRefresh: true,
        );

        // Assert
        expect(result.latitude, tPosition.latitude);
        expect(result.longitude, tPosition.longitude);
        verify(
          mockGeolocatorClient.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).called(1);
      });

      test(
        'should fetch fresh location when cached location is unavailable',
        () async {
          // Arrange
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
          ).thenAnswer((_) async => tPosition);

          // Act
          final LocationResult result = await dataSource.getCurrentLocation();

          // Assert
          expect(result.latitude, tPosition.latitude);
          verify(
            mockGeolocatorClient.getCurrentPosition(
              locationSettings: anyNamed('locationSettings'),
            ),
          ).called(1);
        },
      );

      test('should return error when location service is disabled', () async {
        // Arrange
        when(
          mockGeolocatorClient.isLocationServiceEnabled(),
        ).thenAnswer((_) async => false);

        // Act
        final LocationResult result = await dataSource.getCurrentLocation();

        // Assert
        expect(result.error, 'Location services are disabled');
      });

      test(
        'should return error when permission is denied and request denied',
        () async {
          // Arrange
          when(
            mockGeolocatorClient.isLocationServiceEnabled(),
          ).thenAnswer((_) async => true);
          when(
            mockGeolocatorClient.checkPermission(),
          ).thenAnswer((_) async => LocationPermission.denied);
          when(
            mockGeolocatorClient.requestPermission(),
          ).thenAnswer((_) async => LocationPermission.denied);

          // Act
          final LocationResult result = await dataSource.getCurrentLocation();

          // Assert
          expect(result.error, 'Location permission denied');
        },
      );

      test(
        'falls back to last known position on exception (forceRefresh=true)',
        () async {
          // Arrange
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

          // Act
          final LocationResult result = await dataSource.getCurrentLocation(
            forceRefresh: true,
          );

          // Assert
          expect(result.latitude, tPosition.latitude);
        },
      );

      test('returns error on timeout if no last known position', () async {
        // Arrange
        when(
          mockGeolocatorClient.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockGeolocatorClient.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);
        when(
          mockGeolocatorClient.getLastKnownPosition(),
        ).thenAnswer((_) async => null); // Initially null
        when(
          mockGeolocatorClient.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).thenThrow(TimeoutException('Timeout'));

        // Act
        final LocationResult result = await dataSource.getCurrentLocation();

        // Assert
        expect(result.error, contains('timed out'));
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

      test('returns false when permission denied forever', () async {
        when(
          mockGeolocatorClient.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.denied);
        when(
          mockGeolocatorClient.requestPermission(),
        ).thenAnswer((_) async => LocationPermission.deniedForever);
        when(mockGeolocatorClient.openAppSettings()).thenAnswer((_) async {
          return;
        }); // Future<void>

        final bool result = await dataSource.requestPermission();

        expect(result, false);
      });
    });
    group('getCountryCode', () {
      test('should return EG for coordinates in Egypt when geocoding fails', () async {
        // Arrange
        // (Mocking failure is implicit since we don't mock placemarkFromCoordinates here as it's a mixin/extension or static?
        // Wait, LocationDataSourceImpl calls placemarkFromCoordinates directly which is a global function from geocoding package.
        // It is NOT mocked in this test setup.
        // However, since we are running in a test environment without platform channel setup for geocoding,
        // the real placemarkFromCoordinates will likely throw MissingPluginException or similar, which is caught by the try-catch block.
        // So we can rely on that behavior for the "failure" case.)

        // Act
        final result = await dataSource.getCountryCode(
          30.0444,
          31.2357,
        ); // Cairo

        // Assert
        expect(result, 'EG');
      });

      test(
        'should return null for unknown coordinates when geocoding fails',
        () async {
          // Act
          final result = await dataSource.getCountryCode(0.0, 0.0); // Ocean

          // Assert
          expect(result, null);
        },
      );
    });
  });
}
