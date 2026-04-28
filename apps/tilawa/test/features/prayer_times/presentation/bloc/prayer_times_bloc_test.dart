import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/usecases.dart';
import 'package:tilawa/features/prayer_times/domain/value_objects/prayer_alarm_capability.dart';
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
  CheckPrayerAlarmCapabilityUseCase,
  RequestExactAlarmPermissionUseCase,
  RequestNotificationPermissionUseCase,
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
  late MockCheckPrayerAlarmCapabilityUseCase
  mockCheckPrayerAlarmCapabilityUseCase;
  late MockRequestExactAlarmPermissionUseCase
  mockRequestExactAlarmPermissionUseCase;
  late MockRequestNotificationPermissionUseCase
  mockRequestNotificationPermissionUseCase;

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
    mockCheckPrayerAlarmCapabilityUseCase =
        MockCheckPrayerAlarmCapabilityUseCase();
    mockRequestExactAlarmPermissionUseCase =
        MockRequestExactAlarmPermissionUseCase();
    mockRequestNotificationPermissionUseCase =
        MockRequestNotificationPermissionUseCase();

    bloc = PrayerTimesBloc(
      mockGetPrayerTimesUseCase,
      mockGetMonthlyPrayerTimesUseCase,
      mockGetCurrentLocationUseCase,
      mockGetCountryCodeUseCase,
      mockSavePrayerSettingsUseCase,
      mockLoadPrayerSettingsUseCase,
      mockSchedulePrayerNotificationsUseCase,
      mockCancelPrayerNotificationsUseCase,
      mockCheckPrayerAlarmCapabilityUseCase,
      mockRequestExactAlarmPermissionUseCase,
      mockRequestNotificationPermissionUseCase,
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
  provideDummy<Either<Failure, PrayerAlarmCapability>>(
    Right(
      PrayerAlarmCapability(
        canScheduleExact: false,
        hasNotificationPermission: false,
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

    // --- Notification event tests ---

    const tCapability = PrayerAlarmCapability(
      canScheduleExact: true,
      hasNotificationPermission: true,
    );

    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'checkAlarmCapability emits state with alarmCapability on success',
      build: () {
        when(
          mockCheckPrayerAlarmCapabilityUseCase.call(),
        ).thenAnswer((_) async => const Right(tCapability));
        return bloc;
      },
      act: (b) => b.add(const PrayerTimesEvent.checkAlarmCapability()),
      expect: () => [
        isA<PrayerTimesState>().having(
          (s) => s.alarmCapability,
          'alarmCapability',
          tCapability,
        ),
      ],
    );

    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'checkAlarmCapability emits no state when use case returns Left',
      build: () {
        when(
          mockCheckPrayerAlarmCapabilityUseCase.call(),
        ).thenAnswer((_) async => Left(Failure.unexpectedError('error')));
        return bloc;
      },
      act: (b) => b.add(const PrayerTimesEvent.checkAlarmCapability()),
      expect: () => [],
    );

    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'requestExactAlarmPermission calls use case then re-checks capability',
      build: () {
        when(
          mockRequestExactAlarmPermissionUseCase.call(),
        ).thenAnswer((_) async => const Right(null));
        when(
          mockCheckPrayerAlarmCapabilityUseCase.call(),
        ).thenAnswer((_) async => const Right(tCapability));
        return bloc;
      },
      act: (b) => b.add(const PrayerTimesEvent.requestExactAlarmPermission()),
      verify: (_) {
        verify(mockRequestExactAlarmPermissionUseCase.call()).called(1);
        verify(mockCheckPrayerAlarmCapabilityUseCase.call()).called(1);
      },
    );

    blocTest<PrayerTimesBloc, PrayerTimesState>(
      'requestNotificationPermission calls use case then re-checks capability',
      build: () {
        when(
          mockRequestNotificationPermissionUseCase.call(),
        ).thenAnswer((_) async => const Right(true));
        when(
          mockCheckPrayerAlarmCapabilityUseCase.call(),
        ).thenAnswer((_) async => const Right(tCapability));
        return bloc;
      },
      act: (b) => b.add(const PrayerTimesEvent.requestNotificationPermission()),
      verify: (_) {
        verify(mockRequestNotificationPermissionUseCase.call()).called(1);
        verify(mockCheckPrayerAlarmCapabilityUseCase.call()).called(1);
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
  });
}
