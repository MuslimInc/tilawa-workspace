import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/core/usecases/usecase.dart';
import 'package:muzakri/features/qibla/domain/entities/qibla_direction_entity.dart';
import 'package:muzakri/features/qibla/domain/usecases/check_location_service_use_case.dart';
import 'package:muzakri/features/qibla/domain/usecases/get_qibla_direction_use_case.dart';
import 'package:muzakri/features/qibla/domain/usecases/request_location_permission_use_case.dart';
import 'package:muzakri/features/qibla/presentation/bloc/qibla_bloc.dart';

class MockGetQiblaDirectionUseCase extends Mock
    implements GetQiblaDirectionUseCase {}

class MockCheckLocationServiceUseCase extends Mock
    implements CheckLocationServiceUseCase {}

class MockRequestLocationPermissionUseCase extends Mock
    implements RequestLocationPermissionUseCase {}

void main() {
  late QiblaBloc qiblaBloc;
  late MockGetQiblaDirectionUseCase mockGetQiblaDirectionUseCase;
  late MockCheckLocationServiceUseCase mockCheckLocationServiceUseCase;
  late MockRequestLocationPermissionUseCase
  mockRequestLocationPermissionUseCase;

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    mockGetQiblaDirectionUseCase = MockGetQiblaDirectionUseCase();
    mockCheckLocationServiceUseCase = MockCheckLocationServiceUseCase();
    mockRequestLocationPermissionUseCase =
        MockRequestLocationPermissionUseCase();
    qiblaBloc = QiblaBloc(
      mockGetQiblaDirectionUseCase,
      mockCheckLocationServiceUseCase,
      mockRequestLocationPermissionUseCase,
    );
  });

  tearDown(() {
    qiblaBloc.close();
  });

  const tQiblaDirection = QiblaDirectionEntity(
    qibla: 100,
    direction: 90,
    offset: 10,
  );

  group('CheckLocationService', () {
    blocTest<QiblaBloc, QiblaState>(
      'should emit [success] when service is enabled AND permission is granted',
      setUp: () {
        when(
          () => mockCheckLocationServiceUseCase(any()),
        ).thenAnswer((_) async => const Right(true));

        when(
          () => mockRequestLocationPermissionUseCase(any()),
        ).thenAnswer((_) async => const Right(true));

        when(
          () => mockGetQiblaDirectionUseCase(any()),
        ).thenAnswer((_) => Stream.value(tQiblaDirection));
      },
      build: () => qiblaBloc,
      act: (bloc) => bloc.add(const CheckLocationService()),
      expect: () => [
        const QiblaState(
          status: QiblaStatus.loading,
        ), // Check & Start (deduplicated)
        const QiblaState(
          status: QiblaStatus.success,
          direction: tQiblaDirection,
        ),
      ],
    );

    blocTest<QiblaBloc, QiblaState>(
      'should emit [loading, serviceDisabled] when location service is disabled',
      setUp: () {
        when(
          () => mockCheckLocationServiceUseCase(any()),
        ).thenAnswer((_) async => const Right(false));
      },
      build: () => qiblaBloc,
      act: (bloc) => bloc.add(const CheckLocationService()),
      expect: () => [
        const QiblaState(status: QiblaStatus.loading),
        const QiblaState(status: QiblaStatus.serviceDisabled),
      ],
    );

    blocTest<QiblaBloc, QiblaState>(
      'should emit [loading, permissionDenied] when service enabled but permission denied',
      setUp: () {
        when(
          () => mockCheckLocationServiceUseCase(any()),
        ).thenAnswer((_) async => const Right(true));

        when(
          () => mockRequestLocationPermissionUseCase(any()),
        ).thenAnswer((_) async => const Right(false));
      },
      build: () => qiblaBloc,
      act: (bloc) => bloc.add(const CheckLocationService()),
      expect: () => [
        const QiblaState(status: QiblaStatus.loading),
        const QiblaState(status: QiblaStatus.permissionDenied),
      ],
    );

    blocTest<QiblaBloc, QiblaState>(
      'should emit [error] when stream emits an error',
      setUp: () {
        when(
          () => mockCheckLocationServiceUseCase(any()),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => mockRequestLocationPermissionUseCase(any()),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => mockGetQiblaDirectionUseCase(any()),
        ).thenAnswer((_) => Stream.error(Exception('Stream error')));
      },
      build: () => qiblaBloc,
      act: (bloc) => bloc.add(const CheckLocationService()),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        const QiblaState(status: QiblaStatus.loading),
        const QiblaState(
          status: QiblaStatus.error,
          errorMessage: 'Exception: Stream error',
        ),
      ],
    );

    blocTest<QiblaBloc, QiblaState>(
      'should emit [error] when location service check fails',
      setUp: () {
        when(() => mockCheckLocationServiceUseCase(any())).thenAnswer(
          (_) async => const Left(ServerFailure('Service check failed')),
        );
      },
      build: () => qiblaBloc,
      act: (bloc) => bloc.add(const CheckLocationService()),
      expect: () => [
        const QiblaState(status: QiblaStatus.loading),
        const QiblaState(
          status: QiblaStatus.error,
          errorMessage: 'Service check failed',
        ),
      ],
    );
  });

  group('RequestLocationPermission', () {
    blocTest<QiblaBloc, QiblaState>(
      'should emit [loading, success] when permission is granted after request',
      setUp: () {
        when(
          () => mockRequestLocationPermissionUseCase(any()),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => mockGetQiblaDirectionUseCase(any()),
        ).thenAnswer((_) => Stream.value(tQiblaDirection));
      },
      build: () => qiblaBloc,
      act: (bloc) => bloc.add(const RequestLocationPermission()),
      skip: 1, // Start loading
      expect: () => [
        const QiblaState(
          status: QiblaStatus.success,
          direction: tQiblaDirection,
        ),
      ],
    );

    blocTest<QiblaBloc, QiblaState>(
      'should emit [permissionDenied] when permission is denied after request',
      setUp: () {
        when(
          () => mockRequestLocationPermissionUseCase(any()),
        ).thenAnswer((_) async => const Right(false));
      },
      build: () => qiblaBloc,
      act: (bloc) => bloc.add(const RequestLocationPermission()),
      expect: () => [const QiblaState(status: QiblaStatus.permissionDenied)],
    );

    blocTest<QiblaBloc, QiblaState>(
      'should emit [error] when permission request fails',
      setUp: () {
        when(() => mockRequestLocationPermissionUseCase(any())).thenAnswer(
          (_) async => const Left(ServerFailure('Permission request failed')),
        );
      },
      build: () => qiblaBloc,
      act: (bloc) => bloc.add(const RequestLocationPermission()),
      expect: () => [
        const QiblaState(
          status: QiblaStatus.error,
          errorMessage: 'Permission request failed',
        ),
      ],
    );
  });

  group('StartQiblaStream', () {
    blocTest<QiblaBloc, QiblaState>(
      'should emit [error] when stream times out',
      setUp: () {
        when(() => mockGetQiblaDirectionUseCase(any())).thenAnswer(
          (_) => Stream<QiblaDirectionEntity>.fromFuture(
            Completer<QiblaDirectionEntity>().future,
          ),
        );
      },
      build: () => qiblaBloc,
      act: (bloc) => bloc.add(const StartQiblaStream()),
      wait: const Duration(seconds: 4),
      expect: () => [
        const QiblaState(status: QiblaStatus.loading),
        const QiblaState(
          status: QiblaStatus.error,
          errorMessage:
              'Sensors not responding. If you are on a Simulator, Compass is not supported.',
        ),
      ],
    );

    blocTest<QiblaBloc, QiblaState>(
      'should emit [error] when stream setup fails',
      setUp: () {
        when(
          () => mockGetQiblaDirectionUseCase(any()),
        ).thenThrow(Exception('Setup failed'));
      },
      build: () => qiblaBloc,
      act: (bloc) => bloc.add(const StartQiblaStream()),
      expect: () => [
        const QiblaState(status: QiblaStatus.loading),
        const QiblaState(
          status: QiblaStatus.error,
          errorMessage: 'Exception: Setup failed',
        ),
      ],
    );
  });
}
