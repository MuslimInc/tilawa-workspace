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
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_times_bloc.dart';
import 'package:tilawa/features/prayer_times/presentation/widgets/prayer_settings_sheet.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../../../helpers/hydrated_bloc_test_helper.dart';
import 'prayer_settings_sheet_notification_test.mocks.dart';

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
  late MockCheckPrayerAlarmCapabilityUseCase mockCheckCapability;
  late MockRequestExactAlarmPermissionUseCase mockRequestPermission;
  late MockRequestNotificationPermissionUseCase
  mockRequestNotificationPermission;

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
    mockCheckCapability = MockCheckPrayerAlarmCapabilityUseCase();
    mockRequestPermission = MockRequestExactAlarmPermissionUseCase();
    mockRequestNotificationPermission =
        MockRequestNotificationPermissionUseCase();

    when(
      mockGetCountryCode.call(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      ),
    ).thenAnswer((_) async => null);

    when(mockCheckCapability.call()).thenAnswer(
      (_) async => const Right(
        PrayerAlarmCapability(
          canScheduleExact: true,
          hasNotificationPermission: true,
        ),
      ),
    );

    when(
      mockRequestPermission.call(),
    ).thenAnswer((_) async => const Right<Failure, void>(null));
    when(
      mockRequestNotificationPermission.call(),
    ).thenAnswer((_) async => const Right<Failure, bool>(true));

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
    mockCheckCapability,
    mockRequestPermission,
    mockRequestNotificationPermission,
  );

  Widget buildSubject(PrayerTimesBloc bloc) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // theme omitted in tests
      home: BlocProvider.value(
        value: bloc,
        child: const Scaffold(body: PrayerSettingsSheet()),
      ),
    );
  }

  group('PrayerSettingsSheet — notification section', () {
    testWidgets('renders "Prayer Notifications" section title', (tester) async {
      final bloc = buildBloc();
      await tester.pumpWidget(buildSubject(bloc));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Prayer Notifications'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Prayer Notifications'), findsOneWidget);
      bloc.close();
    });

    testWidgets('renders "All Prayer Notifications" global toggle', (
      tester,
    ) async {
      final bloc = buildBloc();
      await tester.pumpWidget(buildSubject(bloc));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('All Prayer Notifications'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('All Prayer Notifications'), findsOneWidget);
      bloc.close();
    });

    testWidgets('renders "Play Adhan" toggle', (tester) async {
      final bloc = buildBloc();
      await tester.pumpWidget(buildSubject(bloc));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Play Adhan'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Play Adhan'), findsOneWidget);
      bloc.close();
    });

    testWidgets('dispatches checkAlarmCapability event on initState', (
      tester,
    ) async {
      final bloc = buildBloc();
      await tester.pumpWidget(buildSubject(bloc));
      await tester.pump();

      verify(mockCheckCapability.call()).called(greaterThanOrEqualTo(1));
      bloc.close();
    });

    testWidgets(
      'does not show notification permission banner when fully capable',
      (tester) async {
        final bloc = buildBloc();
        bloc.emit(
          const PrayerTimesState(
            alarmCapability: PrayerAlarmCapability(
              canScheduleExact: true,
              hasNotificationPermission: true,
            ),
          ),
        );

        await tester.pumpWidget(buildSubject(bloc));
        await tester.pump();
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pump();

        expect(
          find.textContaining('Notification permission required'),
          findsNothing,
        );
        bloc.close();
      },
    );

    testWidgets(
      'shows notification permission banner when POST_NOTIFICATIONS not granted',
      (tester) async {
        when(mockCheckCapability.call()).thenAnswer(
          (_) async => const Right(
            PrayerAlarmCapability(
              canScheduleExact: true,
              hasNotificationPermission: false,
            ),
          ),
        );

        final bloc = buildBloc();

        await tester.pumpWidget(buildSubject(bloc));
        await tester.pump(); // allow checkAlarmCapability event to complete
        await tester.scrollUntilVisible(
          find.text(
            'Notification permission required to receive prayer alerts.',
          ),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(
          find.text(
            'Notification permission required to receive prayer alerts.',
          ),
          findsOneWidget,
        );
        bloc.close();
      },
    );

    testWidgets(
      'shows exact alarm banner when POST_NOTIFICATIONS granted but exact alarm not granted',
      (tester) async {
        final bloc = buildBloc();

        await tester.pumpWidget(buildSubject(bloc));
        await tester.pump();

        bloc.emit(
          const PrayerTimesState(
            alarmCapability: PrayerAlarmCapability(
              canScheduleExact: false,
              hasNotificationPermission: true,
            ),
          ),
        );
        await tester.pump();

        await tester.scrollUntilVisible(
          find.text(
            'Exact alarm permission required for reliable prayer reminders.',
          ),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(
          find.text(
            'Exact alarm permission required for reliable prayer reminders.',
          ),
          findsOneWidget,
        );
        bloc.close();
      },
    );

    testWidgets('renders in RTL locale without overflow errors', (
      tester,
    ) async {
      final bloc = buildBloc();
      final widget = MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // theme omitted in tests
        home: BlocProvider.value(
          value: bloc,
          child: const Scaffold(body: PrayerSettingsSheet()),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pump();

      // No overflow errors — the layout adapts to RTL without throwing.
      expect(tester.takeException(), isNull);
      bloc.close();
    });
  });
}
