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
  GetCountryCodeUseCase,
  SavePrayerSettingsUseCase,
  LoadPrayerSettingsUseCase,
  SchedulePrayerNotificationsUseCase,
  CancelPrayerNotificationsUseCase,
])
void main() {
  late PrayerTimesBloc bloc;
  late MockGetPrayerTimesUseCase mockGetPrayerTimesUseCase;
  late MockGetMonthlyPrayerTimesUseCase mockGetMonthlyPrayerTimesUseCase;
  late MockGetCurrentLocationUseCase mockGetCurrentLocationUseCase;
  late MockGetCountryCodeUseCase mockGetCountryCodeUseCase;
  late MockSavePrayerSettingsUseCase mockSavePrayerSettingsUseCase;
  late MockLoadPrayerSettingsUseCase mockLoadPrayerSettingsUseCase;
  late MockSchedulePrayerNotificationsUseCase
  mockSchedulePrayerNotificationsUseCase;
  late MockCancelPrayerNotificationsUseCase
  mockCancelPrayerNotificationsUseCase;

  setUp(() {
    mockGetPrayerTimesUseCase = MockGetPrayerTimesUseCase();
    mockGetMonthlyPrayerTimesUseCase = MockGetMonthlyPrayerTimesUseCase();
    mockGetCurrentLocationUseCase = MockGetCurrentLocationUseCase();
    mockGetCountryCodeUseCase = MockGetCountryCodeUseCase();
    mockSavePrayerSettingsUseCase = MockSavePrayerSettingsUseCase();
    mockLoadPrayerSettingsUseCase = MockLoadPrayerSettingsUseCase();
    mockSchedulePrayerNotificationsUseCase =
        MockSchedulePrayerNotificationsUseCase();
    mockCancelPrayerNotificationsUseCase =
        MockCancelPrayerNotificationsUseCase();

    bloc = PrayerTimesBloc(
      mockGetPrayerTimesUseCase,
      mockGetMonthlyPrayerTimesUseCase,
      mockGetCurrentLocationUseCase,
      mockGetCountryCodeUseCase,
      mockSavePrayerSettingsUseCase,
      mockLoadPrayerSettingsUseCase,
      mockSchedulePrayerNotificationsUseCase,
      mockCancelPrayerNotificationsUseCase,
    );

    // Default stub
    when(
      mockGetCountryCodeUseCase.call(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      ),
    ).thenAnswer((_) async => null);

    when(
      mockSchedulePrayerNotificationsUseCase.call(
        settings: anyNamed('settings'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        forceReschedule: anyNamed('forceReschedule'),
      ),
    ).thenAnswer((_) async => const Right(null));

    when(
      mockSavePrayerSettingsUseCase.call(settings: anyNamed('settings')),
    ).thenAnswer((_) async => const Right(null));
  });
  provideDummy<Either<Failure, PrayerSettingsEntity>>(
    const Right(PrayerSettingsEntity()),
  );
  provideDummy<Either<Failure, LocationResult>>(
    Right(LocationResult(latitude: 0, longitude: 0)),
  );
  provideDummy<Either<Failure, void>>(const Right(null));
  provideDummy<Either<Failure, bool>>(const Right(true));
  provideDummy<Either<Failure, PrayerTimeEntity>>(
    Right(
      PrayerTimeEntity(
        date: DateTime.now(),
        fajr: DateTime.now(),
        sunrise: DateTime.now(),
        dhuhr: DateTime.now(),
        asr: DateTime.now(),
        maghrib: DateTime(2023, 1, 1, 17, 30),
        isha: DateTime(2023, 1, 1, 19, 0),
        midnight: DateTime(2023, 1, 1, 23, 30),
        lastThird: DateTime(2023, 1, 2, 2, 0),
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
    midnight: DateTime.now(),
    lastThird: DateTime.now(),
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
        const PrayerTimesState(
          latitude: 10.0,
          longitude: 10.0,
          locationName: 'City',
          status: PrayerTimesStatus.loading,
          settings: PrayerSettingsEntity(
            lastResolvedLatitude: 10.0,
            lastResolvedLongitude: 10.0,
            lastResolvedLocationName: 'City',
          ),
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

    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'persists auto-detected location as last resolved scheduling location',
      build: () {
        when(
          mockLoadPrayerSettingsUseCase.call(),
        ).thenAnswer((_) async => const Right(tSettings));
        when(
          mockGetCurrentLocationUseCase.call(),
        ).thenAnswer((_) async => Right(tLocationResult));
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
      verify: (_) {
        final capturedSettings =
            verify(
                  mockSavePrayerSettingsUseCase.call(
                    settings: captureAnyNamed('settings'),
                  ),
                ).captured.last
                as PrayerSettingsEntity;

        expect(capturedSettings.savedLatitude, isNull);
        expect(capturedSettings.savedLongitude, isNull);
        expect(capturedSettings.lastResolvedLatitude, 10.0);
        expect(capturedSettings.lastResolvedLongitude, 10.0);
        expect(capturedSettings.lastResolvedLocationName, 'City');
      },
    );

    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'does not overwrite manual saved location when loading from saved coordinates',
      build: () {
        when(mockLoadPrayerSettingsUseCase.call()).thenAnswer(
          (_) async => const Right(
            PrayerSettingsEntity(
              savedLatitude: 30.0,
              savedLongitude: 31.0,
              savedLocationName: 'Manual',
              lastResolvedLatitude: 10.0,
              lastResolvedLongitude: 11.0,
              lastResolvedLocationName: 'Auto',
            ),
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
      verify: (_) {
        verifyNever(
          mockSavePrayerSettingsUseCase.call(settings: anyNamed('settings')),
        );
      },
    );
    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'should auto-detect calculation method for Egypt when using ummAlQura settings',
      build: () {
        when(mockLoadPrayerSettingsUseCase.call()).thenAnswer(
          (_) async => const Right(
            PrayerSettingsEntity(
              calculationMethod: CalculationMethod.ummAlQura,
            ),
          ),
        );

        when(mockGetCurrentLocationUseCase.call()).thenAnswer(
          (_) async => Right(
            LocationResult(
              latitude: 30.0444,
              longitude: 31.2357,
              locationName: 'Cairo',
              countryCode: 'EG',
            ),
          ),
        );

        // First settings save call (auto-detection)
        when(
          mockSavePrayerSettingsUseCase.call(settings: anyNamed('settings')),
        ).thenAnswer((_) async => const Right(null));

        // Use captureAny to allow flexible matching since settings object changes
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
      verify: (bloc) {
        verify(mockGetCurrentLocationUseCase.call()).called(1);

        // specific verification for auto-detection
        final capturedSettings =
            verify(
                  mockSavePrayerSettingsUseCase.call(
                    settings: captureAnyNamed('settings'),
                  ),
                ).captured.first
                as PrayerSettingsEntity;

        expect(capturedSettings.calculationMethod, CalculationMethod.egyptian);
      },
    );

    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'should auto-detect calculation method for Egypt when using ummAlQura settings and saved location',
      build: () {
        // Saved location exists (Cairo)
        when(mockLoadPrayerSettingsUseCase.call()).thenAnswer(
          (_) async => const Right(
            PrayerSettingsEntity(
              savedLatitude: 30.0444,
              savedLongitude: 31.2357,
              savedLocationName: 'Cairo',
              calculationMethod: CalculationMethod.ummAlQura, // Default
            ),
          ),
        );

        // Mock GetCountryCode to return EG
        when(
          mockGetCountryCodeUseCase.call(
            latitude: anyNamed('latitude'),
            longitude: anyNamed('longitude'),
          ),
        ).thenAnswer((_) async => 'EG');

        // Expect settings save
        when(
          mockSavePrayerSettingsUseCase.call(settings: anyNamed('settings')),
        ).thenAnswer((_) async => const Right(null));

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
      verify: (bloc) {
        // Should call getCountryCode
        verify(
          mockGetCountryCodeUseCase.call(latitude: 30.0444, longitude: 31.2357),
        ).called(1);

        // Should NOT call getCurrentLocation
        verifyNever(mockGetCurrentLocationUseCase.call());

        // Should save new settings
        final capturedSettings =
            verify(
                  mockSavePrayerSettingsUseCase.call(
                    settings: captureAnyNamed('settings'),
                  ),
                ).captured.first
                as PrayerSettingsEntity;

        expect(capturedSettings.calculationMethod, CalculationMethod.egyptian);

        // Verify that getPrayerTimesUseCase was called with the UPDATED settings
        verify(
          mockGetPrayerTimesUseCase.call(
            latitude: anyNamed('latitude'),
            longitude: anyNamed('longitude'),
            date: anyNamed('date'),
            settings:
                capturedSettings, // Must match the saved (updated) settings
          ),
        ).called(1);
      },
    );

    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'updateSettings triggers internal loadPrayerTimes with forceReschedule=true',
      build: () {
        when(
          mockSavePrayerSettingsUseCase.call(settings: anyNamed('settings')),
        ).thenAnswer((_) async => const Right(null));
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
      seed: () => const PrayerTimesState(
        status: PrayerTimesStatus.loaded,
        latitude: 10.0,
        longitude: 10.0,
      ),
      act: (b) =>
          b.add(const PrayerTimesEvent.updateSettings(PrayerSettingsEntity())),
      verify: (_) {
        verify(
          mockSchedulePrayerNotificationsUseCase.call(
            settings: anyNamed('settings'),
            latitude: anyNamed('latitude'),
            longitude: anyNamed('longitude'),
            forceReschedule: true,
          ),
        ).called(greaterThanOrEqualTo(1));
      },
    );

    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'refreshIfStale does nothing when loaded data is fresh',
      build: () => PrayerTimesBloc(
        mockGetPrayerTimesUseCase,
        mockGetMonthlyPrayerTimesUseCase,
        mockGetCurrentLocationUseCase,
        mockGetCountryCodeUseCase,
        mockSavePrayerSettingsUseCase,
        mockLoadPrayerSettingsUseCase,
        mockSchedulePrayerNotificationsUseCase,
        mockCancelPrayerNotificationsUseCase,
        _FakeShouldRefreshPrayerTimesUseCase(shouldRefresh: false),
      ),
      seed: () => PrayerTimesState(
        status: PrayerTimesStatus.loaded,
        todayPrayerTimes: tPrayerTimes,
      ),
      act: (bloc) => bloc.add(const PrayerTimesEvent.refreshIfStale()),
      expect: () => <PrayerTimesState>[],
      verify: (_) {
        verifyNever(
          mockGetPrayerTimesUseCase.call(
            latitude: anyNamed('latitude'),
            longitude: anyNamed('longitude'),
            date: anyNamed('date'),
            settings: anyNamed('settings'),
          ),
        );
      },
    );

    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'refreshIfStale reloads prayer times with forced reschedule when stale',
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

        return PrayerTimesBloc(
          mockGetPrayerTimesUseCase,
          mockGetMonthlyPrayerTimesUseCase,
          mockGetCurrentLocationUseCase,
          mockGetCountryCodeUseCase,
          mockSavePrayerSettingsUseCase,
          mockLoadPrayerSettingsUseCase,
          mockSchedulePrayerNotificationsUseCase,
          mockCancelPrayerNotificationsUseCase,
          _FakeShouldRefreshPrayerTimesUseCase(shouldRefresh: true),
        );
      },
      seed: () => PrayerTimesState(
        status: PrayerTimesStatus.loaded,
        todayPrayerTimes: tPrayerTimes,
      ),
      act: (bloc) => bloc.add(const PrayerTimesEvent.refreshIfStale()),
      expect: () => [
        PrayerTimesState(
          status: PrayerTimesStatus.loading,
          todayPrayerTimes: tPrayerTimes,
        ),
        PrayerTimesState(
          status: PrayerTimesStatus.loading,
          todayPrayerTimes: tPrayerTimes,
          settings: const PrayerSettingsEntity(
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
      verify: (_) {
        verify(
          mockSchedulePrayerNotificationsUseCase.call(
            settings: anyNamed('settings'),
            latitude: anyNamed('latitude'),
            longitude: anyNamed('longitude'),
            forceReschedule: true,
          ),
        ).called(1);
      },
    );

    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'refreshIfStale is ignored while already loading',
      build: () {
        final fakeRefresh = _FakeShouldRefreshPrayerTimesUseCase(
          shouldRefresh: true,
        );
        addTearDown(() => expect(fakeRefresh.calls, 0));

        return PrayerTimesBloc(
          mockGetPrayerTimesUseCase,
          mockGetMonthlyPrayerTimesUseCase,
          mockGetCurrentLocationUseCase,
          mockGetCountryCodeUseCase,
          mockSavePrayerSettingsUseCase,
          mockLoadPrayerSettingsUseCase,
          mockSchedulePrayerNotificationsUseCase,
          mockCancelPrayerNotificationsUseCase,
          fakeRefresh,
        );
      },
      seed: () => const PrayerTimesState(status: PrayerTimesStatus.loading),
      act: (bloc) => bloc.add(const PrayerTimesEvent.refreshIfStale()),
      expect: () => <PrayerTimesState>[],
    );
  });
}

class _FakeShouldRefreshPrayerTimesUseCase
    implements ShouldRefreshPrayerTimesUseCase {
  _FakeShouldRefreshPrayerTimesUseCase({required this.shouldRefresh});

  final bool shouldRefresh;
  int calls = 0;

  @override
  bool call({required DateTime? loadedDate, Duration? loadedUtcOffset}) {
    calls++;
    return shouldRefresh;
  }
}
