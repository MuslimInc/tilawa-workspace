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
        'should return LocationResult when permission granted and service enabled',
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
          ).thenAnswer((_) async => tPosition);

          // Act
          final LocationResult result = await dataSource.getCurrentLocation();

          // Assert
          expect(result.latitude, tPosition.latitude);
          expect(result.longitude, tPosition.longitude);
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

      test('falls back to last known position on exception', () async {
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
        final LocationResult result = await dataSource.getCurrentLocation();

        // Assert
        expect(result.latitude, tPosition.latitude);
      });

      test('returns error on timeout if no last known position', () async {
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
        ).thenThrow(TimeoutException('Timeout'));
        when(
          mockGeolocatorClient.getLastKnownPosition(),
        ).thenAnswer((_) async => null);

        // Act
        final LocationResult result = await dataSource.getCurrentLocation();

        // Assert
        expect(result.error, contains('timed out'));
      });

      test('falls back to last known position on timeout', () async {
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
        ).thenThrow(TimeoutException('Timeout'));
        when(
          mockGeolocatorClient.getLastKnownPosition(),
        ).thenAnswer((_) async => tPosition);

        // Act
        final LocationResult result = await dataSource.getCurrentLocation();

        // Assert
        expect(result.latitude, tPosition.latitude);
        expect(result.longitude, tPosition.longitude);
      });
      test(
        'returns specific error when both current and last known positions fail',
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
          ).thenThrow(Exception('Generic Error'));
          when(
            mockGeolocatorClient.getLastKnownPosition(),
          ).thenAnswer((_) async => null);

          // Act
          final LocationResult result = await dataSource.getCurrentLocation();

          // Assert
          expect(
            result.error,
            contains('Failed to get location: Exception: Generic Error'),
          );
        },
      );
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
  });
}
