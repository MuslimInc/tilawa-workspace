import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:qibla/qibla.dart';
import 'package:tilawa/core/wrappers/location_service_wrapper.dart';
import 'package:tilawa/core/wrappers/qibla_service_wrapper.dart';
import 'package:tilawa/features/qibla/data/datasources/qibla_data_source.dart';

import 'qibla_data_source_test.mocks.dart';

@GenerateMocks([LocationServiceWrapper, QiblaServiceWrapper])
void main() {
  late QiblaDataSourceImpl dataSource;
  late MockLocationServiceWrapper mockLocationService;
  late MockQiblaServiceWrapper mockQiblaService;

  setUp(() {
    mockLocationService = MockLocationServiceWrapper();
    mockQiblaService = MockQiblaServiceWrapper();
    dataSource = QiblaDataSourceImpl(mockLocationService, mockQiblaService);
  });

  group('qiblaStream', () {
    test('should return stream from QiblaService', () {
      // Arrange
      const qiblaDirection = QiblaDirection(10, 20, 30);
      when(
        mockQiblaService.qiblaStream,
      ).thenAnswer((_) => Stream.value(qiblaDirection));

      // Act
      final Stream<QiblaDirection> result = dataSource.qiblaStream;

      // Assert
      expect(result, emits(qiblaDirection));
      verify(mockQiblaService.qiblaStream);
    });
  });

  group('isLocationServiceEnabled', () {
    test('should call LocationService', () async {
      // Arrange
      when(
        mockLocationService.isLocationServiceEnabled(),
      ).thenAnswer((_) async => true);

      // Act
      final bool result = await dataSource.isLocationServiceEnabled();

      // Assert
      expect(result, true);
      verify(mockLocationService.isLocationServiceEnabled());
    });
  });

  group('checkPermission', () {
    test('should call LocationService', () async {
      // Arrange
      when(
        mockLocationService.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.always);

      // Act
      final LocationPermission result = await dataSource.checkPermission();

      // Assert
      expect(result, LocationPermission.always);
      verify(mockLocationService.checkPermission());
    });
  });

  group('requestPermission', () {
    test('should call LocationService', () async {
      // Arrange
      when(
        mockLocationService.requestPermission(),
      ).thenAnswer((_) async => LocationPermission.whileInUse);

      // Act
      final LocationPermission result = await dataSource.requestPermission();

      // Assert
      expect(result, LocationPermission.whileInUse);
      verify(mockLocationService.requestPermission());
    });
  });
}
