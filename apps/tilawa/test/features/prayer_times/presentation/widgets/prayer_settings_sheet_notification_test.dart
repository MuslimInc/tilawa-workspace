import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/usecases.dart';
import 'package:tilawa/features/prayer_times/domain/value_objects/prayer_alarm_capability.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_permissions_cubit.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_times_bloc.dart';
import 'package:tilawa/features/prayer_times/presentation/widgets/prayer_settings_sheet.dart';
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../../../helpers/hydrated_bloc_test_helper.dart';
import 'prayer_settings_sheet_notification_test.mocks.dart';

@GenerateMocks([
  SettingsCubit,
  PrayerPermissionsCubit,
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
  provideDummy<PrayerPermissionsState>(const PrayerPermissionsState());
  provideDummy<Either<Failure, PrayerSettingsEntity>>(
    const Right(PrayerSettingsEntity()),
  );
  provideDummy<Either<Failure, LocationResult>>(
    Right(LocationResult(latitude: 0, longitude: 0)),
  );
  provideDummy<Either<Failure, void>>(const Right(null));
  provideDummy<Either<Failure, bool>>(const Right(true));
  provideDummy<Either<Failure, PrayerAlarmCapability>>(
    const Right(
      PrayerAlarmCapability(
        canScheduleExact: true,
        hasNotificationPermission: true,
      ),
    ),
  );
  provideDummy<Either<Failure, PrayerTimeEntity>>(
    Right(
      PrayerTimeEntity(
        date: DateTime(2025),
        fajr: DateTime(2025),
        sunrise: DateTime(2025),
        dhuhr: DateTime(2025),
        asr: DateTime(2025),
        maghrib: DateTime(2025),
        isha: DateTime(2025),
        midnight: DateTime(2025),
        lastThird: DateTime(2025),
        latitude: 0,
        longitude: 0,
        timezone: 'UTC',
      ),
    ),
  );

  late MockGetPrayerTimesUseCase mockGetPrayerTimes;
  late MockGetMonthlyPrayerTimesUseCase mockGetMonthlyPrayerTimes;
  late MockGetCurrentLocationUseCase mockGetCurrentLocation;
  late MockGetCountryCodeUseCase mockGetCountryCode;
  late MockSavePrayerSettingsUseCase mockSavePrayerSettings;
  late MockLoadPrayerSettingsUseCase mockLoadPrayerSettings;
  late MockSchedulePrayerNotificationsUseCase mockSchedule;
  late MockCancelPrayerNotificationsUseCase mockCancel;
  late MockPrayerPermissionsCubit mockPermissionsCubit;
  late MockSettingsCubit mockSettingsCubit;

  setUpAll(() async {
    await initializeHydratedStorageForTest();
  });

  setUp(() {
    mockGetPrayerTimes = MockGetPrayerTimesUseCase();
    mockGetMonthlyPrayerTimes = MockGetMonthlyPrayerTimesUseCase();
    mockGetCurrentLocation = MockGetCurrentLocationUseCase();
    mockGetCountryCode = MockGetCountryCodeUseCase();
    mockSavePrayerSettings = MockSavePrayerSettingsUseCase();
    mockLoadPrayerSettings = MockLoadPrayerSettingsUseCase();
    mockSchedule = MockSchedulePrayerNotificationsUseCase();
    mockCancel = MockCancelPrayerNotificationsUseCase();
    mockPermissionsCubit = MockPrayerPermissionsCubit();
    when(mockPermissionsCubit.state).thenReturn(const PrayerPermissionsState());
    when(mockPermissionsCubit.stream).thenAnswer((_) => const Stream.empty());

    mockSettingsCubit = MockSettingsCubit();
    when(mockSettingsCubit.state).thenReturn(const SettingsState());
    when(mockSettingsCubit.stream).thenAnswer((_) => const Stream.empty());

    when(
      mockGetCountryCode.call(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      ),
    ).thenAnswer((_) async => null);

    when(
      mockSchedule.call(
        settings: anyNamed('settings'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        forceReschedule: anyNamed('forceReschedule'),
      ),
    ).thenAnswer((_) async => const Right(null));
  });

  PrayerTimesBloc buildBloc() => PrayerTimesBloc(
    mockGetPrayerTimes,
    mockGetMonthlyPrayerTimes,
    mockGetCurrentLocation,
    mockGetCountryCode,
    mockSavePrayerSettings,
    mockLoadPrayerSettings,
    mockSchedule,
    mockCancel,
  );

  Widget buildSubject(PrayerTimesBloc bloc) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // theme omitted in tests
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider<PrayerPermissionsCubit>.value(
            value: mockPermissionsCubit,
          ),
          BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
        ],
        child: const Scaffold(body: PrayerSettingsSheet()),
      ),
    );
  }

  group('PrayerSettingsSheet — structural refactor', () {
    testWidgets('does NOT render "Prayer Notifications" section', (
      tester,
    ) async {
      final bloc = buildBloc();
      await tester.pumpWidget(buildSubject(bloc));
      await tester.pump();

      expect(find.text('Prayer Notifications'), findsNothing);
      bloc.close();
    });

    testWidgets('does NOT render global notification toggle', (tester) async {
      final bloc = buildBloc();
      await tester.pumpWidget(buildSubject(bloc));
      await tester.pump();

      expect(find.text('All Prayer Notifications'), findsNothing);
      bloc.close();
    });

    testWidgets('still renders "Calculation Method" section', (tester) async {
      final bloc = buildBloc();
      await tester.pumpWidget(buildSubject(bloc));
      await tester.pump();

      expect(find.text('Calculation Method'), findsOneWidget);
      bloc.close();
    });
  });
}
