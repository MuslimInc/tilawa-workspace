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
  provideDummy<Either<Failure, List<PrayerTimeEntity>>>(
    Right(<PrayerTimeEntity>[]),
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
      'restarts in-flight loadPrayerTimes when a newer event arrives',
      build: () {
        when(
          mockLoadPrayerSettingsUseCase.call(),
        ).thenAnswer((_) async => const Right(tSettings));
        when(mockGetCurrentLocationUseCase.call()).thenAnswer(
          (_) => Future<Either<Failure, LocationResult>>.delayed(
            const Duration(milliseconds: 100),
            () => Right(tLocationResult),
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
      act: (bloc) async {
        bloc.add(const PrayerTimesEvent.loadPrayerTimes());
        bloc.add(const PrayerTimesEvent.loadPrayerTimes());
        await Future<void>.delayed(const Duration(milliseconds: 150));
      },
      verify: (_) {
        verify(mockLoadPrayerSettingsUseCase.call()).called(2);
        verify(mockGetCurrentLocationUseCase.call()).called(2);
      },
    );

    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'keeps latest monthly prayer times when month changes quickly',
      build: () {
        final PrayerTimeEntity januaryDay = tPrayerTimes.copyWith(
          date: DateTime(2030, 1, 15),
        );
        final PrayerTimeEntity februaryDay = tPrayerTimes.copyWith(
          date: DateTime(2030, 2, 15),
        );

        when(
          mockGetMonthlyPrayerTimesUseCase.call(
            latitude: 10.0,
            longitude: 10.0,
            year: 2030,
            month: 1,
            settings: tSettings,
          ),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return Right(<PrayerTimeEntity>[januaryDay]);
        });
        when(
          mockGetMonthlyPrayerTimesUseCase.call(
            latitude: 10.0,
            longitude: 10.0,
            year: 2030,
            month: 2,
            settings: tSettings,
          ),
        ).thenAnswer((_) async => Right(<PrayerTimeEntity>[februaryDay]));

        return bloc;
      },
      seed: () => const PrayerTimesState(
        status: PrayerTimesStatus.loaded,
        latitude: 10.0,
        longitude: 10.0,
        settings: tSettings,
      ),
      act: (bloc) async {
        bloc.add(
          const PrayerTimesEvent.loadMonthlyPrayerTimes(year: 2030, month: 1),
        );
        bloc.add(
          const PrayerTimesEvent.loadMonthlyPrayerTimes(year: 2030, month: 2),
        );
        await Future<void>.delayed(const Duration(milliseconds: 150));
      },
      expect: () => <Matcher>[
        isA<PrayerTimesState>().having(
          (PrayerTimesState state) =>
              state.monthlyPrayerTimes.single.date.month,
          'monthly month',
          2,
        ),
      ],
    );

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
            allowOpenSettings: anyNamed('allowOpenSettings'),
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

    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'loadPrayerTimes uses default settings when loadPrayerSettings fails',
      build: () {
        when(
          mockLoadPrayerSettingsUseCase.call(),
        ).thenAnswer(
          (_) async => Left(Failure.unexpectedError('Settings fail')),
        );
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
      verify: (bloc) {
        expect(bloc.state.status, PrayerTimesStatus.loaded);
        expect(bloc.state.settings.savedLatitude, isNull);
        expect(bloc.state.settings.lastResolvedLatitude, 10.0);
        expect(bloc.state.settings.lastResolvedLocationName, 'City');
        expect(bloc.state.todayPrayerTimes, tPrayerTimes);
        verify(mockLoadPrayerSettingsUseCase.call()).called(1);
      },
    );

    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'loadPrayerTimes emits error when prayer time calculation fails',
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
        ).thenAnswer(
          (_) async => Left(Failure.unexpectedError('Calc failed')),
        );
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
        const PrayerTimesState(
          status: PrayerTimesStatus.error,
          settings: PrayerSettingsEntity(
            savedLatitude: 10.0,
            savedLongitude: 10.0,
          ),
          errorMessage: 'Calc failed',
        ),
      ],
    );

    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'loadMonthlyPrayerTimes is a no-op without coordinates',
      build: () => bloc,
      act: (bloc) => bloc.add(
        const PrayerTimesEvent.loadMonthlyPrayerTimes(year: 2030, month: 3),
      ),
      expect: () => <PrayerTimesState>[],
      verify: (_) {
        verifyNever(
          mockGetMonthlyPrayerTimesUseCase.call(
            latitude: anyNamed('latitude'),
            longitude: anyNamed('longitude'),
            year: anyNamed('year'),
            month: anyNamed('month'),
            settings: anyNamed('settings'),
          ),
        );
      },
    );

    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'loadMonthlyPrayerTimes emits errorMessage when monthly fetch fails',
      build: () {
        when(
          mockGetMonthlyPrayerTimesUseCase.call(
            latitude: 10.0,
            longitude: 10.0,
            year: 2030,
            month: 3,
            settings: tSettings,
          ),
        ).thenAnswer(
          (_) async => Left(Failure.unexpectedError('Monthly failed')),
        );
        return bloc;
      },
      seed: () => const PrayerTimesState(
        status: PrayerTimesStatus.loaded,
        latitude: 10.0,
        longitude: 10.0,
        settings: tSettings,
      ),
      act: (bloc) => bloc.add(
        const PrayerTimesEvent.loadMonthlyPrayerTimes(year: 2030, month: 3),
      ),
      expect: () => [
        const PrayerTimesState(
          status: PrayerTimesStatus.loaded,
          latitude: 10.0,
          longitude: 10.0,
          settings: tSettings,
          errorMessage: 'Monthly failed',
        ),
      ],
    );

    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'updateLocation emits error when location fetch fails',
      build: () {
        when(
          mockGetCurrentLocationUseCase.call(
            forceRefresh: anyNamed('forceRefresh'),
            allowOpenSettings: anyNamed('allowOpenSettings'),
          ),
        ).thenAnswer(
          (_) async => Left(Failure.unexpectedError('Location denied')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const PrayerTimesEvent.updateLocation()),
      expect: () => [
        const PrayerTimesState(isLoadingLocation: true),
        const PrayerTimesState(
          isLoadingLocation: false,
          errorMessage: 'Location denied',
        ),
      ],
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
      'updateSettings with recalculation triggers loadPrayerTimes',
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
        settings: PrayerSettingsEntity(
          calculationMethod: CalculationMethod.muslimWorldLeague,
        ),
      ),
      act: (bloc) => bloc.add(
        const PrayerTimesEvent.updateSettings(
          PrayerSettingsEntity(
            calculationMethod: CalculationMethod.egyptian,
          ),
        ),
      ),
      verify: (_) {
        verify(
          mockGetPrayerTimesUseCase.call(
            latitude: anyNamed('latitude'),
            longitude: anyNamed('longitude'),
            date: anyNamed('date'),
            settings: anyNamed('settings'),
          ),
        ).called(1);
      },
    );

    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'updateSettings without recalculation only reschedules notifications',
      build: () {
        when(
          mockSavePrayerSettingsUseCase.call(settings: anyNamed('settings')),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => const PrayerTimesState(
        status: PrayerTimesStatus.loaded,
        latitude: 10.0,
        longitude: 10.0,
        settings: PrayerSettingsEntity(
          fajrNotification: PrayerNotificationSettings(
            mode: PrayerAlertMode.none,
          ),
        ),
      ),
      act: (bloc) => bloc.add(
        const PrayerTimesEvent.updateSettings(
          PrayerSettingsEntity(
            fajrNotification: PrayerNotificationSettings(
              mode: PrayerAlertMode.notification,
            ),
          ),
        ),
      ),
      verify: (_) {
        verify(
          mockSchedulePrayerNotificationsUseCase.call(
            settings: anyNamed('settings'),
            latitude: 10.0,
            longitude: 10.0,
            forceReschedule: true,
          ),
        ).called(1);
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
      'setManualLocation saves coordinates and reloads prayer times',
      build: () {
        when(
          mockSavePrayerSettingsUseCase.call(settings: anyNamed('settings')),
        ).thenAnswer((_) async => const Right(null));
        when(mockLoadPrayerSettingsUseCase.call()).thenAnswer(
          (_) async => const Right(
            PrayerSettingsEntity(
              savedLatitude: 12.0,
              savedLongitude: 13.0,
              savedLocationName: 'Manual',
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
      act: (bloc) => bloc.add(
        const PrayerTimesEvent.setManualLocation(
          latitude: 12,
          longitude: 13,
          locationName: 'Manual',
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.status, PrayerTimesStatus.loaded);
        expect(bloc.state.latitude, 12);
        expect(bloc.state.longitude, 13);
        expect(bloc.state.locationName, 'Manual');
        expect(bloc.state.settings.savedLatitude, 12);
        expect(bloc.state.settings.savedLongitude, 13);
        expect(bloc.state.settings.savedLocationName, 'Manual');

        final PrayerSettingsEntity savedSettings =
            verify(
                  mockSavePrayerSettingsUseCase.call(
                    settings: captureAnyNamed('settings'),
                  ),
                ).captured.first
                as PrayerSettingsEntity;
        expect(savedSettings.lastResolvedLatitude, 12);
        expect(savedSettings.lastResolvedLongitude, 13);

        verify(
          mockGetPrayerTimesUseCase.call(
            latitude: anyNamed('latitude'),
            longitude: anyNamed('longitude'),
            date: anyNamed('date'),
            settings: anyNamed('settings'),
          ),
        ).called(1);
      },
    );

    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'skips persisting last resolved location when coordinates are unchanged',
      build: () {
        when(mockLoadPrayerSettingsUseCase.call()).thenAnswer(
          (_) async => const Right(
            PrayerSettingsEntity(
              calculationMethod: CalculationMethod.muslimWorldLeague,
              lastResolvedLatitude: 10.0,
              lastResolvedLongitude: 10.0,
              lastResolvedLocationName: 'City',
            ),
          ),
        );
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
        verifyNever(
          mockSavePrayerSettingsUseCase.call(settings: anyNamed('settings')),
        );
      },
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
