import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/usecases.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_times_bloc.dart';
import 'package:tilawa_core/errors/failures.dart';

import 'prayer_times_bloc_test.mocks.dart';

@GenerateMocks([
  GetPrayerTimesUseCase,
  GetMonthlyPrayerTimesUseCase,
  GetCurrentLocationUseCase,
  SavePrayerSettingsUseCase,
  LoadPrayerSettingsUseCase,
])
void main() {
  late PrayerTimesBloc bloc;
  late MockGetPrayerTimesUseCase mockGetPrayerTimesUseCase;
  late MockGetMonthlyPrayerTimesUseCase mockGetMonthlyPrayerTimesUseCase;
  late MockGetCurrentLocationUseCase mockGetCurrentLocationUseCase;
  late MockSavePrayerSettingsUseCase mockSavePrayerSettingsUseCase;
  late MockLoadPrayerSettingsUseCase mockLoadPrayerSettingsUseCase;

  setUp(() {
    mockGetPrayerTimesUseCase = MockGetPrayerTimesUseCase();
    mockGetMonthlyPrayerTimesUseCase = MockGetMonthlyPrayerTimesUseCase();
    mockGetCurrentLocationUseCase = MockGetCurrentLocationUseCase();
    mockSavePrayerSettingsUseCase = MockSavePrayerSettingsUseCase();
    mockLoadPrayerSettingsUseCase = MockLoadPrayerSettingsUseCase();

    bloc = PrayerTimesBloc(
      mockGetPrayerTimesUseCase,
      mockGetMonthlyPrayerTimesUseCase,
      mockGetCurrentLocationUseCase,
      mockSavePrayerSettingsUseCase,
      mockLoadPrayerSettingsUseCase,
    );
  });
  provideDummy<Either<Failure, PrayerSettingsEntity>>(
    const Right(PrayerSettingsEntity()),
  );
  provideDummy<Either<Failure, LocationResult>>(
    Right(LocationResult(latitude: 0, longitude: 0)),
  );
  provideDummy<Either<Failure, void>>(const Right(null));
  provideDummy<Either<Failure, PrayerTimeEntity>>(
    Right(
      PrayerTimeEntity(
        date: DateTime.now(),
        fajr: DateTime.now(),
        sunrise: DateTime.now(),
        dhuhr: DateTime.now(),
        asr: DateTime.now(),
        maghrib: DateTime.now(),
        isha: DateTime.now(),
        latitude: 0,
        longitude: 0,
      ),
    ),
  );
  // End of provideDummy block

  tearDown(() {
    bloc.close();
  });

  const tSettings = PrayerSettingsEntity();
  final tLocationResult = LocationResult(
    latitude: 10.0,
    longitude: 10.0,
    locationName: 'City',
  );
  final tPrayerTimes = PrayerTimeEntity(
    date: DateTime.now(),
    fajr: DateTime.now(),
    sunrise: DateTime.now(),
    dhuhr: DateTime.now(),
    asr: DateTime.now(),
    maghrib: DateTime.now(),
    isha: DateTime.now(),
    latitude: 10.0,
    longitude: 10.0,
    timezone: 'UTC',
  );

  group('PrayerTimesBloc', () {
    test('initial state is correct', () {
      expect(bloc.state, const PrayerTimesState());
    });

    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'emits [locationRequired] when no saved location and location fetch fails',
      build: () {
        when(
          mockLoadPrayerSettingsUseCase.call(),
        ).thenAnswer((_) async => const Right(tSettings));
        when(
          mockGetCurrentLocationUseCase.call(),
        ).thenAnswer((_) async => Left(Failure.unexpectedError('Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const PrayerTimesEvent.loadPrayerTimes()),
      expect: () => [
        const PrayerTimesState(status: PrayerTimesStatus.loading),

        // Removed duplicate loading
        const PrayerTimesState(
          status: PrayerTimesStatus.loading,
          isLoadingLocation: true,
        ),
        // Error state from location failure
        const PrayerTimesState(
          status: PrayerTimesStatus.locationRequired,
          errorMessage: 'Error',
        ),
        // Final state check (though logic stops)
      ],
    );

    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'emits [loading, loaded] when location is saved and prayer times fetched successfully',
      build: () {
        when(mockLoadPrayerSettingsUseCase.call()).thenAnswer(
          (_) async => const Right(
            PrayerSettingsEntity(savedLatitude: 10.0, savedLongitude: 10.0),
          ),
        );
        when(
          mockGetPrayerTimesUseCase.call(
            latitude: anyNamed('latitude'),
            longitude: anyNamed('longitude'),
            date: anyNamed('date'),
            settings: anyNamed('settings'),
          ),
        ).thenAnswer((_) async => Right(tPrayerTimes));
        return bloc;
      },
      act: (bloc) => bloc.add(const PrayerTimesEvent.loadPrayerTimes()),
      expect: () => [
        const PrayerTimesState(status: PrayerTimesStatus.loading),
        const PrayerTimesState(
          status: PrayerTimesStatus.loading,
          settings: PrayerSettingsEntity(
            savedLatitude: 10.0,
            savedLongitude: 10.0,
          ),
        ),
        isA<PrayerTimesState>()
            .having((s) => s.status, 'status', PrayerTimesStatus.loaded)
            .having(
              (s) => s.todayPrayerTimes,
              'todayPrayerTimes',
              tPrayerTimes,
            ),
      ],
    );

    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'emits [isLoadingLocation=true, loaded] when updating location',
      build: () {
        when(
          mockGetCurrentLocationUseCase.call(
            forceRefresh: anyNamed('forceRefresh'),
          ),
        ).thenAnswer((_) async => Right(tLocationResult));
        // Mocks for the triggered loadPrayerTimes
        when(
          mockLoadPrayerSettingsUseCase.call(),
        ).thenAnswer((_) async => const Right(tSettings));
        when(
          mockGetPrayerTimesUseCase.call(
            latitude: anyNamed('latitude'),
            longitude: anyNamed('longitude'),
            date: anyNamed('date'),
            settings: anyNamed('settings'),
          ),
        ).thenAnswer((_) async => Right(tPrayerTimes));
        return bloc;
      },
      act: (bloc) => bloc.add(const PrayerTimesEvent.updateLocation()),
      expect: () => [
        const PrayerTimesState(isLoadingLocation: true),
        const PrayerTimesState(
          latitude: 10.0,
          longitude: 10.0,
          locationName: 'City',
        ),
        const PrayerTimesState(
          latitude: 10.0,
          longitude: 10.0,
          locationName: 'City',
          status: PrayerTimesStatus.loading,
        ),
        const PrayerTimesState(
          latitude: 10.0,
          longitude: 10.0,
          locationName: 'City',
          status: PrayerTimesStatus.loading,
          isLoadingLocation: true,
        ),
        const PrayerTimesState(
          latitude: 10.0,
          longitude: 10.0,
          locationName: 'City',
          status: PrayerTimesStatus.loading,
        ),
        isA<PrayerTimesState>()
            .having((s) => s.status, 'status', PrayerTimesStatus.loaded)
            .having((s) => s.todayPrayerTimes, 'todayPrayerTimes', tPrayerTimes)
            .having((s) => s.locationName, 'locationName', 'City')
            .having((s) => s.isLoadingLocation, 'isLoadingLocation', false),
      ],
    );

    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'emits updated settings when updating settings',
      build: () {
        when(
          mockSavePrayerSettingsUseCase.call(settings: anyNamed('settings')),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const PrayerTimesEvent.updateSettings(tSettings)),
      expect: () => [const PrayerTimesState()],
    );
  });
}
