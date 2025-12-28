import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:qibla/qibla.dart';
import 'package:tilawa/features/qibla/data/datasources/qibla_data_source.dart';
import 'package:tilawa/features/qibla/data/repositories/qibla_repository_impl.dart';
import 'package:tilawa/features/qibla/domain/entities/qibla_direction_entity.dart';

import 'qibla_repository_impl_test.mocks.dart';

@GenerateMocks([QiblaDataSource])
void main() {
  late QiblaRepositoryImpl repository;
  late MockQiblaDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockQiblaDataSource();
    repository = QiblaRepositoryImpl(mockDataSource);
  });

  group('getQiblaDirection', () {
    test(
      'should return stream of QiblaDirectionEntity mapped from QiblaDirection',
      () {
        // Arrange
        // QiblaDirection doesn't have a const constructor usually, inspecting it would be better but assuming standard.
        // Based on typical package structure.
        const qiblaDirection = QiblaDirection(10, 20, 30);
        when(
          mockDataSource.qiblaStream,
        ).thenAnswer((_) => Stream.value(qiblaDirection));

        // Act
        final Stream<QiblaDirectionEntity> result = repository
            .getQiblaDirection();

        // Assert
        expect(
          result,
          emits(
            const QiblaDirectionEntity(qibla: 10, direction: 20, offset: 30),
          ),
        );
      },
    );
  });

  group('isLocationServiceEnabled', () {
    test('should return true when data source returns true', () async {
      // Arrange
      when(
        mockDataSource.isLocationServiceEnabled(),
      ).thenAnswer((_) async => true);

      // Act
      final bool result = await repository.isLocationServiceEnabled();

      // Assert
      expect(result, true);
      verify(mockDataSource.isLocationServiceEnabled());
    });

    test('should return false when data source returns false', () async {
      // Arrange
      when(
        mockDataSource.isLocationServiceEnabled(),
      ).thenAnswer((_) async => false);

      // Act
      final bool result = await repository.isLocationServiceEnabled();

      // Assert
      expect(result, false);
      verify(mockDataSource.isLocationServiceEnabled());
    });
  });

  group('requestLocationPermission', () {
    test(
      'should return true when permission is always allowed initially',
      () async {
        // Arrange
        when(
          mockDataSource.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.always);

        // Act
        final bool result = await repository.requestLocationPermission();

        // Assert
        expect(result, true);
        verify(mockDataSource.checkPermission());
        verifyNever(mockDataSource.requestPermission());
      },
    );

    test(
      'should request permission and return true when denied initially and allowed after request',
      () async {
        // Arrange
        when(
          mockDataSource.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.denied);
        when(
          mockDataSource.requestPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);

        // Act
        final bool result = await repository.requestLocationPermission();

        // Assert
        expect(result, true);
        verify(mockDataSource.checkPermission());
        verify(mockDataSource.requestPermission());
      },
    );

    test('should return false when permission is denied forever', () async {
      // Arrange
      when(
        mockDataSource.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.deniedForever);

      // Act
      final bool result = await repository.requestLocationPermission();

      // Assert
      expect(result, false);
      verify(mockDataSource.checkPermission());
      verifyNever(mockDataSource.requestPermission());
    });
  });
}
