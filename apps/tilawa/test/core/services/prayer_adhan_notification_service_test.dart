import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/services/navigation_service.dart';
import 'package:tilawa/core/services/notification_permission_service.dart';
import 'package:tilawa/core/services/prayer_adhan_notification_service.dart';
import 'package:tilawa/core/services/prayer_notification_config.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';
import 'package:tilawa/features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

import 'prayer_adhan_notification_service_test.mocks.dart';

@GenerateMocks([
  INotificationDispatcher,
  FlutterLocalNotificationsPlugin,
  SharedPreferencesAsync,
  NavigationService,
  AnalyticsService,
  IAdhanAlarmPlayer,
  NotificationPermissionService,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PrayerAdhanNotificationService service;
  late MockINotificationDispatcher mockDispatcher;
  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late MockSharedPreferencesAsync mockPrefs;
  late MockNavigationService mockNav;
  late MockAnalyticsService mockAnalytics;
  late MockIAdhanAlarmPlayer mockAdhanPlayer;
  late MockNotificationPermissionService mockNotificationPermissions;

  // Prayer times all set 2 hours in the future so none are skipped as past.
  final DateTime now = DateTime.now();

  PrayerTimeEntity buildFutureDay(int dayOffset) {
    final DateTime date = now.add(Duration(days: dayOffset));
    return PrayerTimeEntity(
      date: date,
      fajr: now.add(Duration(days: dayOffset, hours: 2)),
      sunrise: now.add(Duration(days: dayOffset, hours: 3)),
      dhuhr: now.add(Duration(days: dayOffset, hours: 6)),
      asr: now.add(Duration(days: dayOffset, hours: 9)),
      maghrib: now.add(Duration(days: dayOffset, hours: 12)),
      isha: now.add(Duration(days: dayOffset, hours: 15)),
      midnight: now.add(Duration(days: dayOffset, hours: 18)),
      lastThird: now.add(Duration(days: dayOffset, hours: 20)),
      latitude: 30.0,
      longitude: 31.0,
      timezone: 'UTC',
    );
  }

  const PrayerSettingsEntity allEnabled = PrayerSettingsEntity(
    savedLatitude: 30.0,
    savedLongitude: 31.0,
  );

  void stubPrefsDefault() {
    when(mockPrefs.getString(any)).thenAnswer((_) async => null);
    when(mockPrefs.setString(any, any)).thenAnswer((_) async {});
    when(mockPrefs.remove(any)).thenAnswer((_) async {});
    when(mockPrefs.getInt(any)).thenAnswer((_) async => null);
    when(mockPrefs.setInt(any, any)).thenAnswer((_) async {});
  }

  void stubPluginDefault() {
    when(
      mockPlugin.zonedSchedule(
        id: anyNamed('id'),
        title: anyNamed('title'),
        body: anyNamed('body'),
        scheduledDate: anyNamed('scheduledDate'),
        notificationDetails: anyNamed('notificationDetails'),
        androidScheduleMode: anyNamed('androidScheduleMode'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
        payload: anyNamed('payload'),
      ),
    ).thenAnswer((_) async {});
    when(mockPlugin.cancel(id: anyNamed('id'))).thenAnswer((_) async {});
    when(
      mockPlugin.show(
        id: anyNamed('id'),
        title: anyNamed('title'),
        body: anyNamed('body'),
        notificationDetails: anyNamed('notificationDetails'),
        payload: anyNamed('payload'),
      ),
    ).thenAnswer((_) async {});
  }

  setUp(() {
    mockDispatcher = MockINotificationDispatcher();
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    mockPrefs = MockSharedPreferencesAsync();
    mockNav = MockNavigationService();
    mockAnalytics = MockAnalyticsService();
    mockAdhanPlayer = MockIAdhanAlarmPlayer();
    mockNotificationPermissions = MockNotificationPermissionService();

    when(mockDispatcher.notificationsPlugin).thenReturn(mockPlugin);
    when(
      mockDispatcher.initialize(
        createHighImportanceChannel: anyNamed('createHighImportanceChannel'),
      ),
    ).thenAnswer((_) async {});
    when(
      mockDispatcher.registerHandler(
        serviceId: anyNamed('serviceId'),
        notificationIds: anyNamed('notificationIds'),
        handler: anyNamed('handler'),
      ),
    ).thenReturn(null);
    when(
      mockDispatcher.registerPayloadHandler(
        serviceId: anyNamed('serviceId'),
        matcher: anyNamed('matcher'),
        handler: anyNamed('handler'),
      ),
    ).thenReturn(null);

    when(
      mockAdhanPlayer.onNotificationTapped,
    ).thenAnswer((_) => const Stream.empty());
    when(mockAdhanPlayer.isSupported).thenReturn(false);
    when(mockAdhanPlayer.cancelAllAdhans()).thenAnswer((_) async {});
    when(
      mockNotificationPermissions.isPermissionGranted(),
    ).thenAnswer((_) async => true);
    when(
      mockAnalytics.logEvent(any, parameters: anyNamed('parameters')),
    ).thenAnswer((_) async {});

    stubPrefsDefault();
    stubPluginDefault();

    service = PrayerAdhanNotificationService(
      mockPrefs,
      mockDispatcher,
      mockNav,
      mockAnalytics,
      mockAdhanPlayer,
      mockNotificationPermissions,
    );
  });

  // Helper that initializes the service (required before calling schedule).
  Future<void> initialize() => service.initialize();

  group('PrayerAdhanNotificationService', () {
    group('schedulePrayerNotifications', () {
      test(
        'schedules 5 notifications per day when all prayers are enabled',
        () async {
          await initialize();

          final List<PrayerTimeEntity> days = [
            buildFutureDay(0),
            buildFutureDay(1),
          ];

          await service.schedulePrayerNotifications(
            settings: allEnabled,
            prayerTimesForDays: days,
          );

          // 2 days × 5 prayers = 10 zonedSchedule calls
          verify(
            mockPlugin.zonedSchedule(
              id: anyNamed('id'),
              title: anyNamed('title'),
              body: anyNamed('body'),
              scheduledDate: anyNamed('scheduledDate'),
              notificationDetails: anyNamed('notificationDetails'),
              androidScheduleMode: anyNamed('androidScheduleMode'),
              matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
              payload: anyNamed('payload'),
            ),
          ).called(10);
        },
      );

      test(
        'schedules 70 notifications for 14 days with all prayers enabled',
        () async {
          await initialize();

          final List<PrayerTimeEntity> days = List.generate(14, buildFutureDay);

          await service.schedulePrayerNotifications(
            settings: allEnabled,
            prayerTimesForDays: days,
          );

          // 14 days × 5 prayers = 70 zonedSchedule calls
          verify(
            mockPlugin.zonedSchedule(
              id: anyNamed('id'),
              title: anyNamed('title'),
              body: anyNamed('body'),
              scheduledDate: anyNamed('scheduledDate'),
              notificationDetails: anyNamed('notificationDetails'),
              androidScheduleMode: anyNamed('androidScheduleMode'),
              matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
              payload: anyNamed('payload'),
            ),
          ).called(70);
        },
      );

      test('schedules 0 notifications for a disabled prayer', () async {
        await initialize();

        // Disable Fajr only.
        final PrayerSettingsEntity fajrDisabled = allEnabled.copyWith(
          fajrNotification: allEnabled.fajrNotification.copyWith(
            mode: PrayerAlertMode.none,
          ),
        );

        final List<PrayerTimeEntity> days = [buildFutureDay(0)];

        await service.schedulePrayerNotifications(
          settings: fajrDisabled,
          prayerTimesForDays: days,
        );

        // 1 day × 4 prayers (no fajr) = 4 calls
        verify(
          mockPlugin.zonedSchedule(
            id: anyNamed('id'),
            title: anyNamed('title'),
            body: anyNamed('body'),
            scheduledDate: anyNamed('scheduledDate'),
            notificationDetails: anyNamed('notificationDetails'),
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        ).called(4);
      });

      test('skips past alarms without scheduling', () async {
        await initialize();

        // All prayer times are 2 hours in the PAST.
        final DateTime past = DateTime.now().subtract(const Duration(hours: 2));
        final PrayerTimeEntity pastDay = PrayerTimeEntity(
          date: past,
          fajr: past,
          sunrise: past,
          dhuhr: past,
          asr: past,
          maghrib: past,
          isha: past,
          midnight: past,
          lastThird: past,
          latitude: 30.0,
          longitude: 31.0,
          timezone: 'UTC',
        );

        await service.schedulePrayerNotifications(
          settings: allEnabled,
          prayerTimesForDays: [pastDay],
          forceReschedule: true,
        );

        verifyNever(
          mockPlugin.zonedSchedule(
            id: anyNamed('id'),
            title: anyNamed('title'),
            body: anyNamed('body'),
            scheduledDate: anyNamed('scheduledDate'),
            notificationDetails: anyNamed('notificationDetails'),
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        );
      });

      test('uses minutesBefore offset to compute scheduled time', () async {
        await initialize();

        // Set all prayers to minutesBefore = 10.
        final PrayerSettingsEntity settings10 = allEnabled.copyWith(
          fajrNotification: allEnabled.fajrNotification.copyWith(
            minutesBefore: 10,
          ),
        );

        // Fajr is exactly 11 minutes in the future — minus 10 = 1 min in
        // future, so it should be scheduled; a 9-min future time would be
        // skipped after the offset is applied.
        final DateTime fajrTime = DateTime.now().add(
          const Duration(minutes: 11),
        );
        final PrayerTimeEntity day = PrayerTimeEntity(
          date: fajrTime,
          fajr: fajrTime,
          sunrise: fajrTime.add(const Duration(hours: 1)),
          dhuhr: fajrTime.add(const Duration(hours: 4)),
          asr: fajrTime.add(const Duration(hours: 7)),
          maghrib: fajrTime.add(const Duration(hours: 10)),
          isha: fajrTime.add(const Duration(hours: 13)),
          midnight: fajrTime.add(const Duration(hours: 16)),
          lastThird: fajrTime.add(const Duration(hours: 19)),
          latitude: 30.0,
          longitude: 31.0,
          timezone: 'UTC',
        );

        await service.schedulePrayerNotifications(
          settings: settings10,
          prayerTimesForDays: [day],
          forceReschedule: true,
        );

        // Fajr (11min future - 10min offset = 1min future) should schedule.
        // The other 4 prayers are further in the future → all 5 scheduled.
        verify(
          mockPlugin.zonedSchedule(
            id: anyNamed('id'),
            title: anyNamed('title'),
            body: anyNamed('body'),
            scheduledDate: anyNamed('scheduledDate'),
            notificationDetails: anyNamed('notificationDetails'),
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        ).called(5);
      });

      test('skips Flutter Local Notification scheduling when native adhan '
          'scheduling succeeds (XOR routing — AdhanPlaybackService '
          'posts the foreground-service notification at fire time)', () async {
        await initialize();
        when(mockAdhanPlayer.isSupported).thenReturn(true);
        when(
          mockAdhanPlayer.scheduleAdhan(
            id: anyNamed('id'),
            scheduledTime: anyNamed('scheduledTime'),
            prayerName: anyNamed('prayerName'),
            prayerKey: anyNamed('prayerKey'),
          ),
        ).thenAnswer((_) async => true);

        final PrayerSettingsEntity playAdhan = allEnabled.copyWith(
          fajrNotification: allEnabled.fajrNotification.copyWith(
            mode: PrayerAlertMode.adhan,
          ),
        );

        await service.schedulePrayerNotifications(
          settings: playAdhan,
          prayerTimesForDays: [buildFutureDay(0)],
          forceReschedule: true,
        );

        // When the native adhan player accepts every prayer, the service
        // intentionally does NOT schedule a parallel FLN notification —
        // the native AdhanPlaybackService creates a mediaPlayback
        // foreground-service notification at fire time. Scheduling an
        // FLN here would cause duplicate visual notifications.
        verifyNever(
          mockPlugin.zonedSchedule(
            id: anyNamed('id'),
            title: anyNamed('title'),
            body: anyNamed('body'),
            scheduledDate: anyNamed('scheduledDate'),
            notificationDetails: anyNamed('notificationDetails'),
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        );
        // And the native pipeline must have been invoked once per prayer.
        verify(
          mockAdhanPlayer.scheduleAdhan(
            id: anyNamed('id'),
            scheduledTime: anyNamed('scheduledTime'),
            prayerName: anyNamed('prayerName'),
            prayerKey: anyNamed('prayerKey'),
          ),
        ).called(5);
      });

      test(
        'falls back to adhan channel (with sound) when native adhan scheduling fails',
        () async {
          await initialize();
          when(mockAdhanPlayer.isSupported).thenReturn(true);
          when(
            mockAdhanPlayer.scheduleAdhan(
              id: anyNamed('id'),
              scheduledTime: anyNamed('scheduledTime'),
              prayerName: anyNamed('prayerName'),
              prayerKey: anyNamed('prayerKey'),
            ),
          ).thenAnswer((_) async => false);

          final PrayerSettingsEntity playAdhan = allEnabled.copyWith(
            fajrNotification: allEnabled.fajrNotification.copyWith(
              mode: PrayerAlertMode.adhan,
            ),
          );

          await service.schedulePrayerNotifications(
            settings: playAdhan,
            prayerTimesForDays: [buildFutureDay(0)],
            forceReschedule: true,
          );

          // Verify zonedSchedule was called with the regular adhan channel (with sound).
          final verification = verify(
            mockPlugin.zonedSchedule(
              id: anyNamed('id'),
              title: anyNamed('title'),
              body: anyNamed('body'),
              scheduledDate: anyNamed('scheduledDate'),
              notificationDetails: captureAnyNamed('notificationDetails'),
              androidScheduleMode: anyNamed('androidScheduleMode'),
              matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
              payload: anyNamed('payload'),
            ),
          );

          final captured = verification.captured;
          bool foundAdhanWithSound = false;
          for (final details in captured) {
            if (details is NotificationDetails &&
                details.android?.channelId ==
                    PrayerNotificationConfig.adhanChannelId) {
              foundAdhanWithSound = true;
              break;
            }
          }
          expect(foundAdhanWithSound, isTrue);
          verify(
            mockAnalytics.logEvent(
              'adhan_fallback_used',
              parameters: anyNamed('parameters'),
            ),
          ).called(5);
        },
      );

      test(
        'suppresses scheduling and clears dedup when notification permission is denied',
        () async {
          await initialize();
          when(
            mockNotificationPermissions.isPermissionGranted(),
          ).thenAnswer((_) async => false);

          await service.schedulePrayerNotifications(
            settings: allEnabled,
            prayerTimesForDays: [buildFutureDay(0)],
            forceReschedule: true,
          );

          verifyNever(
            mockPlugin.zonedSchedule(
              id: anyNamed('id'),
              title: anyNamed('title'),
              body: anyNamed('body'),
              scheduledDate: anyNamed('scheduledDate'),
              notificationDetails: anyNamed('notificationDetails'),
              androidScheduleMode: anyNamed('androidScheduleMode'),
              matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
              payload: anyNamed('payload'),
            ),
          );
          verify(
            mockPrefs.remove(PrayerNotificationConfig.dedupDateKey),
          ).called(1);
          verify(
            mockPrefs.remove(PrayerNotificationConfig.settingsFingerprintKey),
          ).called(1);
          verify(
            mockAnalytics.logEvent(
              'permission_revoked_cleanup_completed',
              parameters: anyNamed('parameters'),
            ),
          ).called(1);
        },
      );

      test(
        'exception during zonedSchedule is caught and does not throw',
        () async {
          await initialize();

          when(
            mockPlugin.zonedSchedule(
              id: anyNamed('id'),
              title: anyNamed('title'),
              body: anyNamed('body'),
              scheduledDate: anyNamed('scheduledDate'),
              notificationDetails: anyNamed('notificationDetails'),
              androidScheduleMode: anyNamed('androidScheduleMode'),
              matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
              payload: anyNamed('payload'),
            ),
          ).thenThrow(Exception('Platform channel error'));

          expect(
            () async => service.schedulePrayerNotifications(
              settings: allEnabled,
              prayerTimesForDays: [buildFutureDay(0)],
              forceReschedule: true,
            ),
            returnsNormally,
          );
        },
      );

      test(
        'dedup: same date and fingerprint → skips cancel and schedule',
        () async {
          // Use a Map-backed prefs stub so stored values are visible in
          // subsequent getString reads — simulates real SharedPreferences.
          final Map<String, String?> store = {};
          when(mockPrefs.getString(any)).thenAnswer(
            (inv) async => store[inv.positionalArguments[0] as String],
          );
          when(mockPrefs.setString(any, any)).thenAnswer((inv) async {
            store[inv.positionalArguments[0] as String] =
                inv.positionalArguments[1] as String;
          });

          await initialize();

          final List<PrayerTimeEntity> days = [buildFutureDay(1)];

          // First call: no stored dedup → schedules and writes dedup keys.
          await service.schedulePrayerNotifications(
            settings: allEnabled,
            prayerTimesForDays: days,
          );

          // Verify that dedup keys were stored.
          expect(store[PrayerNotificationConfig.dedupDateKey], isNotNull);

          // Reset plugin call counts for the second call.
          clearInteractions(mockPlugin);

          // Second call: same settings & days → dedup hit → no scheduling.
          await service.schedulePrayerNotifications(
            settings: allEnabled,
            prayerTimesForDays: days,
          );

          verifyNever(
            mockPlugin.zonedSchedule(
              id: anyNamed('id'),
              title: anyNamed('title'),
              body: anyNamed('body'),
              scheduledDate: anyNamed('scheduledDate'),
              notificationDetails: anyNamed('notificationDetails'),
              androidScheduleMode: anyNamed('androidScheduleMode'),
              matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
              payload: anyNamed('payload'),
            ),
          );
          verifyNever(mockPlugin.cancel(id: anyNamed('id')));
        },
      );

      test(
        'dedup: same date but different fingerprint → reschedules',
        () async {
          await initialize();

          final List<PrayerTimeEntity> days = [buildFutureDay(0)];
          final String today = _todayDateKey();

          // Stored fingerprint is deliberately different.
          when(
            mockPrefs.getString(PrayerNotificationConfig.dedupDateKey),
          ).thenAnswer((_) async => today);
          when(
            mockPrefs.getString(
              PrayerNotificationConfig.settingsFingerprintKey,
            ),
          ).thenAnswer((_) async => 'stale_fingerprint');

          await service.schedulePrayerNotifications(
            settings: allEnabled,
            prayerTimesForDays: days,
          );

          // 1 day × 5 prayers = 5 calls
          verify(
            mockPlugin.zonedSchedule(
              id: anyNamed('id'),
              title: anyNamed('title'),
              body: anyNamed('body'),
              scheduledDate: anyNamed('scheduledDate'),
              notificationDetails: anyNamed('notificationDetails'),
              androidScheduleMode: anyNamed('androidScheduleMode'),
              matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
              payload: anyNamed('payload'),
            ),
          ).called(5);
        },
      );

      test('forceReschedule=true bypasses dedup and always schedules', () async {
        // Map-backed prefs so first call stores dedup, second sees it.
        final Map<String, String?> store = {};
        when(mockPrefs.getString(any)).thenAnswer(
          (inv) async => store[inv.positionalArguments[0] as String],
        );
        when(mockPrefs.setString(any, any)).thenAnswer((inv) async {
          store[inv.positionalArguments[0] as String] =
              inv.positionalArguments[1] as String;
        });

        await initialize();

        final List<PrayerTimeEntity> days = [buildFutureDay(1)];

        // First call stores the dedup keys.
        await service.schedulePrayerNotifications(
          settings: allEnabled,
          prayerTimesForDays: days,
        );
        clearInteractions(mockPlugin);

        // Second call with forceReschedule=true must bypass dedup and schedule.
        await service.schedulePrayerNotifications(
          settings: allEnabled,
          prayerTimesForDays: days,
          forceReschedule: true,
        );

        // forceReschedule bypasses dedup → 5 calls
        verify(
          mockPlugin.zonedSchedule(
            id: anyNamed('id'),
            title: anyNamed('title'),
            body: anyNamed('body'),
            scheduledDate: anyNamed('scheduledDate'),
            notificationDetails: anyNamed('notificationDetails'),
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        ).called(5);
      });

      test('does not schedule when prayerTimesForDays is empty', () async {
        await initialize();

        await service.schedulePrayerNotifications(
          settings: allEnabled,
          prayerTimesForDays: [],
          forceReschedule: true,
        );

        verifyNever(
          mockPlugin.zonedSchedule(
            id: anyNamed('id'),
            title: anyNamed('title'),
            body: anyNamed('body'),
            scheduledDate: anyNamed('scheduledDate'),
            notificationDetails: anyNamed('notificationDetails'),
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        );
      });
    });

    group('cancelAllPrayerNotifications', () {
      test(
        'cancels all 5 static IDs and all dynamic IDs in the 14-day range',
        () async {
          await initialize();

          await service.cancelAllPrayerNotifications();

          // 5 static + 14 days × 5 = 75 total cancel calls
          verify(mockPlugin.cancel(id: anyNamed('id'))).called(75);
          verify(mockAdhanPlayer.cancelAllAdhans()).called(1);
        },
      );

      test('cancels dynamic ID for day 0 fajr correctly', () async {
        await initialize();

        await service.cancelAllPrayerNotifications();

        verify(
          mockPlugin.cancel(
            id: PrayerNotificationConfig.dynamicId(0, PrayerType.fajr),
          ),
        ).called(1);
      });

      test('exception during cancel is caught and does not throw', () async {
        await initialize();

        when(
          mockPlugin.cancel(id: anyNamed('id')),
        ).thenThrow(Exception('cancel error'));

        expect(
          () async => service.cancelAllPrayerNotifications(),
          returnsNormally,
        );
      });
    });

    group('initialize', () {
      test(
        'completes without error even when FlutterTimezone throws',
        () async {
          // FlutterTimezone always throws MissingPluginException in unit tests.
          // The service catches it and falls back to UTC.
          expect(() async => service.initialize(), returnsNormally);
        },
      );

      test('is idempotent — second call is a no-op', () async {
        await service.initialize();
        await service.initialize();

        // dispatcher.initialize should only be called once.
        verify(
          mockDispatcher.initialize(
            createHighImportanceChannel: anyNamed(
              'createHighImportanceChannel',
            ),
          ),
        ).called(1);
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Private helpers that replicate the service's internal logic for test setup.
// ---------------------------------------------------------------------------

String _todayDateKey() {
  final DateTime now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
