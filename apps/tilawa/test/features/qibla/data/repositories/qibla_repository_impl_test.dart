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

  Stream<QiblaDirection> timedQiblaStream(
    List<QiblaDirection> values, {
    Duration interval = const Duration(milliseconds: 130),
  }) async* {
    for (final QiblaDirection value in values) {
      yield value;
      await Future<void>.delayed(interval);
    }
  }

  group('getQiblaDirection', () {
    test(
      'should return stream of QiblaDirectionEntity mapped from QiblaDirection',
      () async {
        // Arrange
        const qiblaDirection = QiblaDirection(-10, 370, 725, accuracy: 45);
        when(
          mockDataSource.qiblaStream,
        ).thenAnswer((_) => timedQiblaStream([qiblaDirection]));

        // Act
        final QiblaDirectionEntity result = await repository
            .getQiblaDirection()
            .first;

        // Assert
        expect(
          result,
          const QiblaDirectionEntity(
            qibla: 350,
            direction: 10,
            offset: 5,
            accuracy: 45,
          ),
        );
        expect(result.hasPoorCompassAccuracy, isTrue);
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

  group('getQiblaDirection - tolerance distinct behavior', () {
    test(
      'filters jitter within tolerance and emits meaningful changes',
      () async {
        // Arrange
        const direction1 = QiblaDirection(100, 200, 300);
        const direction2 = QiblaDirection(
          100.3,
          200.2,
          300.4,
        ); // Within 0.5 tolerance
        const direction3 = QiblaDirection(
          101.1,
          201.0,
          301.0,
        ); // Exceeds tolerance

        when(mockDataSource.qiblaStream).thenAnswer(
          (_) => timedQiblaStream([direction1, direction2, direction3]),
        );

        // Act
        final List<QiblaDirectionEntity> emissions = await repository
            .getQiblaDirection()
            .toList();

        // Assert
        expect(emissions.length, 2);
        expect(emissions[0].qibla, 100);
        expect(emissions[1].qibla, closeTo(101.1, 0.0001));
      },
    );

    test(
      'handles wrap-around angles correctly in tolerance comparison',
      () async {
        // Arrange
        const direction1 = QiblaDirection(359.9, 359.9, 359.9);
        const direction2 = QiblaDirection(
          0.1,
          0.1,
          0.1,
        ); // 0.2 apart via wrap-around
        const direction3 = QiblaDirection(
          1.2,
          1.2,
          1.2,
        ); // >0.5 apart from direction2

        when(mockDataSource.qiblaStream).thenAnswer(
          (_) => timedQiblaStream([direction1, direction2, direction3]),
        );

        // Act
        final List<QiblaDirectionEntity> emissions = await repository
            .getQiblaDirection()
            .toList();

        // Assert
        expect(emissions.length, 2);
        expect(emissions[0].qibla, closeTo(359.9, 0.0001));
        expect(emissions[1].qibla, closeTo(1.2, 0.0001));
      },
    );

    test('emits when compass accuracy changes from good to poor', () async {
      // Arrange
      const direction1 = QiblaDirection(100, 200, 300, accuracy: 15);
      const direction2 = QiblaDirection(100.1, 200.1, 300.1, accuracy: 45);

      when(
        mockDataSource.qiblaStream,
      ).thenAnswer((_) => timedQiblaStream([direction1, direction2]));

      // Act
      final List<QiblaDirectionEntity> emissions = await repository
          .getQiblaDirection()
          .toList();

      // Assert
      expect(emissions.length, 2);
      expect(emissions[0].hasPoorCompassAccuracy, isFalse);
      expect(emissions[1].hasPoorCompassAccuracy, isTrue);
    });

    test(
      'filters isolated heading spike without blocking nearby updates',
      () async {
        // Arrange
        const direction1 = QiblaDirection(276.9, 52.8, 135.9);
        const spike = QiblaDirection(224.1, 0.0, 135.9);
        const direction2 = QiblaDirection(275.5, 51.4, 135.9);

        when(
          mockDataSource.qiblaStream,
        ).thenAnswer((_) => timedQiblaStream([direction1, spike, direction2]));

        // Act
        final List<QiblaDirectionEntity> emissions = await repository
            .getQiblaDirection()
            .toList();

        // Assert
        expect(emissions.length, 2);
        expect(emissions[0].direction, closeTo(52.8, 0.0001));
        expect(emissions[1].direction, closeTo(51.4, 0.0001));
      },
    );

    test('emits large heading jump after consecutive confirmation', () async {
      // Arrange
      const direction1 = QiblaDirection(276.9, 52.8, 135.9);
      const jump1 = QiblaDirection(224.1, 0.0, 135.9);
      const jump2 = QiblaDirection(225.1, 1.0, 135.9);

      when(
        mockDataSource.qiblaStream,
      ).thenAnswer((_) => timedQiblaStream([direction1, jump1, jump2]));

      // Act
      final List<QiblaDirectionEntity> emissions = await repository
          .getQiblaDirection()
          .toList();

      // Assert
      expect(emissions.length, 2);
      expect(emissions[0].direction, closeTo(52.8, 0.0001));
      expect(emissions[1].direction, closeTo(1.0, 0.0001));
    });
  });
}
