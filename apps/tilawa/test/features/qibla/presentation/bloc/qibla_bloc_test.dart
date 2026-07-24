import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/qibla/domain/entities/qibla_direction_entity.dart';
import 'package:tilawa/features/qibla/domain/usecases/check_location_service_use_case.dart';
import 'package:tilawa/features/qibla/domain/usecases/get_qibla_direction_use_case.dart';
import 'package:tilawa/features/qibla/domain/usecases/request_location_permission_use_case.dart';
import 'package:tilawa/features/qibla/presentation/bloc/qibla_bloc.dart';
import 'package:tilawa/features/qibla/presentation/constants/qibla_error_codes.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:vibration_platform_interface/vibration_platform_interface.dart';

class MockGetQiblaDirectionUseCase extends Mock
    implements GetQiblaDirectionUseCase {}

class MockCheckLocationServiceUseCase extends Mock
    implements CheckLocationServiceUseCase {}

class MockRequestLocationPermissionUseCase extends Mock
    implements RequestLocationPermissionUseCase {}

class FakeVibrationPlatform extends VibrationPlatform {
  bool hasVibratorValue = true;
  bool hasAmplitudeControlValue = true;
  final List<Map<String, Object>> vibrateCalls = <Map<String, Object>>[];

  @override
  Future<bool> hasVibrator() async => hasVibratorValue;

  @override
  Future<bool> hasAmplitudeControl() async => hasAmplitudeControlValue;

  @override
  Future<void> vibrate({
    int duration = 500,
    List<int> pattern = const [],
    int repeat = -1,
    List<int> intensities = const [],
    int amplitude = -1,
    double sharpness = 0.5,
  }) async {
    vibrateCalls.add(<String, Object>{
      'duration': duration,
      'pattern': pattern,
      'repeat': repeat,
      'intensities': intensities,
      'amplitude': amplitude,
      'sharpness': sharpness,
    });
  }

  @override
  Future<void> cancel() async {}
}

void main() {
  late QiblaBloc qiblaBloc;
  late MockGetQiblaDirectionUseCase mockGetQiblaDirectionUseCase;
  late MockCheckLocationServiceUseCase mockCheckLocationServiceUseCase;
  late MockRequestLocationPermissionUseCase
  mockRequestLocationPermissionUseCase;
  late VibrationPlatform originalVibrationPlatform;
  late FakeVibrationPlatform fakeVibrationPlatform;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    originalVibrationPlatform = VibrationPlatform.instance;
  });

  tearDownAll(() {
    VibrationPlatform.instance = originalVibrationPlatform;
  });

  setUp(() {
    fakeVibrationPlatform = FakeVibrationPlatform();
    VibrationPlatform.instance = fakeVibrationPlatform;
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
          errorMessage: QiblaErrorCodes.sensorFailed,
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
          errorMessage: QiblaErrorCodes.locationFailed,
        ),
      ],
    );

    blocTest<QiblaBloc, QiblaState>(
      'should emit [error] when permission check fails during service check',
      setUp: () {
        when(
          () => mockCheckLocationServiceUseCase(any()),
        ).thenAnswer((_) async => const Right(true));
        when(() => mockRequestLocationPermissionUseCase(any())).thenAnswer(
          (_) async => const Left(ServerFailure('Permission check failed')),
        );
      },
      build: () => qiblaBloc,
      act: (bloc) => bloc.add(const CheckLocationService()),
      expect: () => [
        const QiblaState(status: QiblaStatus.loading),
        const QiblaState(
          status: QiblaStatus.error,
          errorMessage: QiblaErrorCodes.permissionFailed,
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
      'should emit [loading, permissionDenied] when permission is denied after request',
      setUp: () {
        when(
          () => mockRequestLocationPermissionUseCase(any()),
        ).thenAnswer((_) async => const Right(false));
      },
      build: () => qiblaBloc,
      act: (bloc) => bloc.add(const RequestLocationPermission()),
      expect: () => [
        const QiblaState(status: QiblaStatus.loading),
        const QiblaState(status: QiblaStatus.permissionDenied),
      ],
    );

    blocTest<QiblaBloc, QiblaState>(
      'should emit [loading, error] when permission request fails',
      setUp: () {
        when(() => mockRequestLocationPermissionUseCase(any())).thenAnswer(
          (_) async => const Left(ServerFailure('Permission request failed')),
        );
      },
      build: () => qiblaBloc,
      act: (bloc) => bloc.add(const RequestLocationPermission()),
      expect: () => [
        const QiblaState(status: QiblaStatus.loading),
        const QiblaState(
          status: QiblaStatus.error,
          errorMessage: QiblaErrorCodes.permissionFailed,
        ),
      ],
    );
  });

  group('StartQiblaStream', () {
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
          errorMessage: QiblaErrorCodes.sensorFailed,
        ),
      ],
    );
  });

  group('StopQiblaStream', () {
    blocTest<QiblaBloc, QiblaState>(
      'should not emit any new state when stopped',
      build: () => qiblaBloc,
      act: (bloc) => bloc.add(const StopQiblaStream()),
      expect: () => [],
    );
  });

  group('CheckLocationService re-entry', () {
    blocTest<QiblaBloc, QiblaState>(
      'skips re-initialization when success stream is already active',
      setUp: () {
        when(
          () => mockCheckLocationServiceUseCase(any()),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => mockRequestLocationPermissionUseCase(any()),
        ).thenAnswer((_) async => const Right(true));
        when(() => mockGetQiblaDirectionUseCase(any())).thenAnswer(
          (_) => Stream<QiblaDirectionEntity>.value(tQiblaDirection),
        );
      },
      build: () => qiblaBloc,
      act: (bloc) async {
        bloc.add(const CheckLocationService());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const CheckLocationService());
      },
      expect: () => [
        const QiblaState(status: QiblaStatus.loading),
        const QiblaState(
          status: QiblaStatus.success,
          direction: tQiblaDirection,
        ),
      ],
      verify: (_) {
        verify(() => mockCheckLocationServiceUseCase(any())).called(1);
      },
    );
  });

  group('QiblaErrorOccurred', () {
    blocTest<QiblaBloc, QiblaState>(
      'emits error state with message',
      build: () => qiblaBloc,
      act: (bloc) =>
          bloc.add(const QiblaErrorOccurred(QiblaErrorCodes.sensorFailed)),
      expect: () => [
        const QiblaState(
          status: QiblaStatus.error,
          errorMessage: QiblaErrorCodes.sensorFailed,
        ),
      ],
    );
  });

  group('Qibla alignment vibration', () {
    const alignedDirection = QiblaDirectionEntity(
      qibla: 10,
      direction: 10,
      offset: 10,
    );
    const stillAlignedDirection = QiblaDirectionEntity(
      qibla: 11,
      direction: 11,
      offset: 10,
    );
    const unalignedDirection = QiblaDirectionEntity(
      qibla: 70,
      direction: 70,
      offset: 10,
    );

    test('vibrates once when entering the accepted Qibla range', () async {
      qiblaBloc.add(const UpdateQiblaDirection(alignedDirection));
      qiblaBloc.add(const UpdateQiblaDirection(stillAlignedDirection));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(fakeVibrationPlatform.vibrateCalls, hasLength(1));
    });

    test('vibrates again only after leaving and re-entering range', () async {
      qiblaBloc.add(const UpdateQiblaDirection(alignedDirection));
      qiblaBloc.add(const UpdateQiblaDirection(unalignedDirection));
      qiblaBloc.add(const UpdateQiblaDirection(stillAlignedDirection));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(fakeVibrationPlatform.vibrateCalls, hasLength(2));
    });

    test('does not vibrate when device vibration is unsupported', () async {
      fakeVibrationPlatform.hasVibratorValue = false;

      qiblaBloc.add(const UpdateQiblaDirection(alignedDirection));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(fakeVibrationPlatform.vibrateCalls, isEmpty);
    });

    test('vibrates without amplitude control when unsupported', () async {
      fakeVibrationPlatform.hasAmplitudeControlValue = false;

      qiblaBloc.add(const UpdateQiblaDirection(alignedDirection));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(fakeVibrationPlatform.vibrateCalls, hasLength(1));
      expect(fakeVibrationPlatform.vibrateCalls.single['amplitude'], -1);
    });
  });
}
