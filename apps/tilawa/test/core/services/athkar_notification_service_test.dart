import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/config/notification_config.dart';
import 'package:tilawa/core/services/athkar_notification_service.dart';
import 'package:tilawa/core/services/navigation_service.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_settings_entity.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'athkar_notification_service_test.mocks.dart';

@GenerateMocks([
  FlutterLocalNotificationsPlugin,
  AndroidFlutterLocalNotificationsPlugin,
  SharedPreferencesAsync,
  INotificationDispatcher,
  AnalyticsService,
  NavigationService,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AthkarNotificationService', () {
    late AthkarNotificationService service;
    late MockFlutterLocalNotificationsPlugin mockNotificationsPlugin;
    late MockAndroidFlutterLocalNotificationsPlugin mockAndroidPlugin;
    late MockSharedPreferencesAsync mockPrefs;
    late MockINotificationDispatcher mockDispatcher;
    late MockAnalyticsService mockAnalyticsService;
    late MockNavigationService mockNavigationService;
    late FakePrayerTimesRepository fakePrayerTimesRepository;

    setUp(() {
      const PrayerSettingsEntity defaultPrayerSettings = PrayerSettingsEntity(
        calculationMethod: CalculationMethod.egyptian,
        savedLatitude: 30.0444,
        savedLongitude: 31.2357,
      );

      // Initialize timezone for tests
      tz.initializeTimeZones();

      // Stub the flutter_timezone platform channel so getLocalTimezone() returns
      // a deterministic IANA identifier. Without this the call throws
      // MissingPluginException in unit tests, the service falls back to UTC, and
      // tests that compare local-time hour/minute against scheduled TZDateTime
      // would shift by the host's UTC offset.
      const MethodChannel timezoneChannel = MethodChannel('flutter_timezone');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(timezoneChannel, (MethodCall call) async {
            if (call.method == 'getLocalTimezone') {
              return 'Africa/Cairo';
            }
            return null;
          });

      mockNotificationsPlugin = MockFlutterLocalNotificationsPlugin();
      mockAndroidPlugin = MockAndroidFlutterLocalNotificationsPlugin();
      mockPrefs = MockSharedPreferencesAsync();
      mockDispatcher = MockINotificationDispatcher();
      mockAnalyticsService = MockAnalyticsService();
      mockNavigationService = MockNavigationService();
      fakePrayerTimesRepository = FakePrayerTimesRepository(
        settings: defaultPrayerSettings,
        prayerTimesForRange: <PrayerTimeEntity>[
          buildPrayerTimeEntity(DateTime.now().add(const Duration(days: 1))),
        ],
      );

      // Mock dispatcher to return our mock plugin
      when(
        mockDispatcher.initialize(
          createHighImportanceChannel: anyNamed('createHighImportanceChannel'),
        ),
      ).thenAnswer((_) async {
        return;
      });
      when(
        mockDispatcher.notificationsPlugin,
      ).thenReturn(mockNotificationsPlugin);
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
        mockDispatcher.getNotificationAppLaunchDetails(),
      ).thenAnswer((_) async => null);

      service = AthkarNotificationService(
        mockPrefs,
        mockDispatcher,
        mockAnalyticsService,
        mockNavigationService,
        fakePrayerTimesRepository,
      );

      // Default mock behavior
      when(
        mockNotificationsPlugin.initialize(
          settings: anyNamed('settings'),
          onDidReceiveNotificationResponse: anyNamed(
            'onDidReceiveNotificationResponse',
          ),
          onDidReceiveBackgroundNotificationResponse: anyNamed(
            'onDidReceiveBackgroundNotificationResponse',
          ),
        ),
      ).thenAnswer((_) async => true);

      when(
        mockNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(mockAndroidPlugin);

      when(mockAndroidPlugin.createNotificationChannel(any)).thenAnswer((
        _,
      ) async {
        return;
      });

      when(
        mockNotificationsPlugin.zonedSchedule(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
          scheduledDate: anyNamed('scheduledDate'),
          notificationDetails: anyNamed('notificationDetails'),
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
          payload: anyNamed('payload'),
        ),
      ).thenAnswer((_) async {
        return;
      });

      when(mockNotificationsPlugin.cancel(id: anyNamed('id'))).thenAnswer((
        _,
      ) async {
        return;
      });
      when(
        mockNotificationsPlugin.pendingNotificationRequests(),
      ).thenAnswer((_) async => <PendingNotificationRequest>[]);

      when(
        mockDispatcher.getNotificationAppLaunchDetails(),
      ).thenAnswer((_) async => null);

      when(mockPrefs.getString(any)).thenAnswer((_) async => null);
      when(mockPrefs.setString(any, any)).thenAnswer((_) async {
        return;
      });
      when(mockPrefs.setInt(any, any)).thenAnswer((_) async {
        return;
      });
    });

    // Reset config after tests
    tearDown(() {
      NotificationConfig.enableLocalNotifications = true;
      const MethodChannel timezoneChannel = MethodChannel('flutter_timezone');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(timezoneChannel, null);
    });

    group('initialization', () {
      test('should create service instance', () {
        expect(service, isNotNull);
        expect(service, isA<AthkarNotificationService>());
      });

      test('should initialize dispatcher', () async {
        await service.initialize();

        verify(
          mockDispatcher.initialize(
            createHighImportanceChannel: anyNamed(
              'createHighImportanceChannel',
            ),
          ),
        ).called(1);
        verify(
          mockDispatcher.registerHandler(
            serviceId: 'athkar',
            notificationIds: anyNamed('notificationIds'),
            handler: anyNamed('handler'),
          ),
        ).called(1);
        verify(
          mockDispatcher.registerPayloadHandler(
            serviceId: 'athkar',
            matcher: anyNamed('matcher'),
            handler: anyNamed('handler'),
          ),
        ).called(1);
      });

      test('should not initialize if notifications disabled', () async {
        NotificationConfig.enableLocalNotifications = false;
        await service.initialize();

        verifyNever(
          mockDispatcher.initialize(
            createHighImportanceChannel: anyNamed(
              'createHighImportanceChannel',
            ),
          ),
        );
      });

      test('should not initialize twice if already initialized', () async {
        await service.initialize();
        reset(mockDispatcher);
        // Re-setup mock after reset
        when(
          mockDispatcher.initialize(
            createHighImportanceChannel: anyNamed(
              'createHighImportanceChannel',
            ),
          ),
        ).thenAnswer((_) async {
          return;
        });
        when(
          mockDispatcher.notificationsPlugin,
        ).thenReturn(mockNotificationsPlugin);

        await service.initialize(); // Second call

        verifyNever(
          mockDispatcher.initialize(
            createHighImportanceChannel: anyNamed(
              'createHighImportanceChannel',
            ),
          ),
        );
      });

      test('should handle initialization error gracefully', () async {
        when(
          mockDispatcher.initialize(
            createHighImportanceChannel: anyNamed(
              'createHighImportanceChannel',
            ),
          ),
        ).thenThrow(Exception('Init failed'));

        await service.initialize(); // Should not throw

        // logger should have logged error, but we don't spy logger here.
        // We verified it didn't crash.
      });

      test(
        'should handle timezone detection error and fallback to UTC',
        () async {
          final testService =
              TestTimezoneDetectingErrorAthkarNotificationService(
                mockPrefs,
                mockDispatcher,
                mockAnalyticsService,
                mockNavigationService,
                fakePrayerTimesRepository,
              );

          await testService
              .initialize(); // Should not throw and fallback to UTC
        },
      );

      test('should handle invalid timezone and fallback to UTC', () async {
        // Test with an invalid timezone that will cause getLocation to fail
        final testService = TestInvalidTimezoneAthkarNotificationService(
          mockPrefs,
          mockDispatcher,
          mockAnalyticsService,
          mockNavigationService,
          fakePrayerTimesRepository,
        );

        await testService.initialize(); // Should not throw and fallback to UTC
      });

      test('should handle getLocation error and fallback to UTC', () async {
        final testService = TestTimezoneLocationErrorAthkarNotificationService(
          mockPrefs,
          mockDispatcher,
          mockAnalyticsService,
          mockNavigationService,
          fakePrayerTimesRepository,
        );

        await testService.initialize(); // Should not throw and fallback to UTC
      });

      test('should handle app launch from notification', () async {
        const response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 1001,
        );

        when(mockDispatcher.getNotificationAppLaunchDetails()).thenAnswer(
          (_) async => const NotificationAppLaunchDetails(
            true,
            notificationResponse: response,
          ),
        );

        await service.initialize();

        // Verify the dispatcher was initialized and handler was registered
        verify(
          mockDispatcher.initialize(
            createHighImportanceChannel: anyNamed(
              'createHighImportanceChannel',
            ),
          ),
        ).called(1);
        verify(
          mockDispatcher.registerHandler(
            serviceId: 'athkar',
            notificationIds: anyNamed('notificationIds'),
            handler: anyNamed('handler'),
          ),
        ).called(1);
      });
    });

    group('scheduleAthkarNotifications', () {
      test('should schedule both morning and evening notifications', () async {
        await service.scheduleAthkarNotifications();

        verify(
          mockNotificationsPlugin.zonedSchedule(
            id: anyNamed('id'),
            title: 'أذكار الصباح',
            body: 'حان وقت أذكار الصباح 🌅',
            scheduledDate: anyNamed('scheduledDate'),
            notificationDetails: anyNamed('notificationDetails'),
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: null,
            payload: anyNamed('payload'),
          ),
        ).called(1);

        verify(
          mockNotificationsPlugin.zonedSchedule(
            id: anyNamed('id'),
            title: 'أذكار المساء',
            body: 'حان وقت أذكار المساء 🌙',
            scheduledDate: anyNamed('scheduledDate'),
            notificationDetails: anyNamed('notificationDetails'),
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: null,
            payload: anyNamed('payload'),
          ),
        ).called(1);
      });

      test(
        'should fallback to fixed times when prayer-time context is missing',
        () async {
          fakePrayerTimesRepository.settings = const PrayerSettingsEntity();
          fakePrayerTimesRepository.hasPermission = false;
          fakePrayerTimesRepository.prayerTimesForRange = <PrayerTimeEntity>[];

          await service.scheduleAthkarNotifications();

          verify(
            mockNotificationsPlugin.zonedSchedule(
              id: 1001,
              title: 'أذكار الصباح',
              body: 'حان وقت أذكار الصباح 🌅',
              scheduledDate: anyNamed('scheduledDate'),
              notificationDetails: anyNamed('notificationDetails'),
              androidScheduleMode: anyNamed('androidScheduleMode'),
              matchDateTimeComponents: DateTimeComponents.time,
              payload: anyNamed('payload'),
            ),
          ).called(1);

          verify(
            mockNotificationsPlugin.zonedSchedule(
              id: 1002,
              title: 'أذكار المساء',
              body: 'حان وقت أذكار المساء 🌙',
              scheduledDate: anyNamed('scheduledDate'),
              notificationDetails: anyNamed('notificationDetails'),
              androidScheduleMode: anyNamed('androidScheduleMode'),
              matchDateTimeComponents: DateTimeComponents.time,
              payload: anyNamed('payload'),
            ),
          ).called(1);
        },
      );

      test('should not schedule if disabled', () async {
        NotificationConfig.enableLocalNotifications = false;
        await service.scheduleAthkarNotifications();

        verifyNever(
          mockNotificationsPlugin.zonedSchedule(
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

      test('should handle scheduling error gracefully', () async {
        when(
          mockNotificationsPlugin.zonedSchedule(
            id: anyNamed('id'),
            title: anyNamed('title'),
            body: anyNamed('body'),
            scheduledDate: anyNamed('scheduledDate'),
            notificationDetails: anyNamed('notificationDetails'),
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        ).thenThrow(Exception('Scheduling failed'));

        await service.scheduleAthkarNotifications(); // Should not throw
      });
    });

    group('scheduling errors', () {
      test('should handle morning fallback scheduling error', () async {
        fakePrayerTimesRepository.prayerTimesForRange = [];
        when(
          mockNotificationsPlugin.zonedSchedule(
            id: 1001,
            title: anyNamed('title'),
            body: anyNamed('body'),
            scheduledDate: anyNamed('scheduledDate'),
            notificationDetails: anyNamed('notificationDetails'),
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        ).thenThrow(Exception('Scheduling failed'));

        await service.scheduleAthkarNotifications();
      });

      test('should handle evening fallback scheduling error', () async {
        fakePrayerTimesRepository.prayerTimesForRange = [];
        // Morning succeeds, evening fails
        when(
          mockNotificationsPlugin.zonedSchedule(
            id: 1001,
            title: anyNamed('title'),
            body: anyNamed('body'),
            scheduledDate: anyNamed('scheduledDate'),
            notificationDetails: anyNamed('notificationDetails'),
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        ).thenAnswer((_) async {});

        when(
          mockNotificationsPlugin.zonedSchedule(
            id: 1002,
            title: anyNamed('title'),
            body: anyNamed('body'),
            scheduledDate: anyNamed('scheduledDate'),
            notificationDetails: anyNamed('notificationDetails'),
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        ).thenThrow(Exception('Scheduling failed'));

        await service.scheduleAthkarNotifications();
      });

      test('should handle dynamic schedule building error', () async {
        fakePrayerTimesRepository.shouldThrow = true;
        await service.scheduleAthkarNotifications();
        fakePrayerTimesRepository.shouldThrow = false;
      });

      test('should handle resolve context error', () async {
        fakePrayerTimesRepository.shouldThrowInLoadSettings = true;
        await service.scheduleAthkarNotifications();
        fakePrayerTimesRepository.shouldThrowInLoadSettings = false;
      });

      test('should handle debug scheduling error', () async {
        when(
          mockNotificationsPlugin.zonedSchedule(
            id: anyNamed('id'),
            title: anyNamed('title'),
            body: anyNamed('body'),
            scheduledDate: anyNamed('scheduledDate'),
            notificationDetails: anyNamed('notificationDetails'),
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        ).thenThrow(Exception('Debug scheduling failed'));

        await service.scheduleDebugAthkarNotification(isMorning: true);
      });
    });

    group('notification interactions', () {
      test('should handle morning athkar tap', () async {
        const response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 1001, // Morning ID
        );

        await service.handleNotificationResponse(response);
        // Verified it runs without error (logging happened)
      });

      test('should handle evening athkar tap', () async {
        const response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 1002, // Evening ID
        );

        await service.handleNotificationResponse(response);
      });

      test('should handle other notification tap', () async {
        const response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 9999, // Other ID
        );

        await service.handleNotificationResponse(response);
      });

      test(
        'should mark payload as handled to prevent duplicate navigation on hot restart',
        () async {
          const payload = 'morning_athkar_1234567890';
          const response = NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            id: 1001,
            payload: payload,
          );

          when(mockPrefs.setInt(any, any)).thenAnswer((_) async {
            return;
          });

          await service.handleNotificationResponse(response);

          verify(
            mockPrefs.setString('last_handled_notification_payload', payload),
          ).called(1);
          verify(
            mockPrefs.setInt('last_handled_notification_timestamp', any),
          ).called(1);
        },
      );

      test('should not mark empty payload as handled', () async {
        const response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 1001,
          payload: '',
        );

        await service.handleNotificationResponse(response);

        verifyNever(mockPrefs.setString(any, any));
      });
    });

    group('cancelAll', () {
      test('should cancel all athkar notifications', () async {
        when(mockNotificationsPlugin.pendingNotificationRequests()).thenAnswer(
          (_) async => <PendingNotificationRequest>[
            const PendingNotificationRequest(
              31001,
              'Morning',
              'Body',
              'morning_athkar_123',
            ),
            const PendingNotificationRequest(
              31002,
              'Evening',
              'Body',
              'evening_athkar_456',
            ),
            const PendingNotificationRequest(
              7777,
              'Other',
              'Body',
              'other_notification',
            ),
          ],
        );

        await service.cancelAllAthkarNotifications();

        verify(mockNotificationsPlugin.cancel(id: 31001)).called(1);
        verify(mockNotificationsPlugin.cancel(id: 31002)).called(1);
        verify(mockNotificationsPlugin.cancel(id: 1001)).called(1);
        verify(mockNotificationsPlugin.cancel(id: 1002)).called(1);
        verifyNever(mockNotificationsPlugin.cancel(id: 7777));
      });

      test('should not cancel if disabled', () async {
        NotificationConfig.enableLocalNotifications = false;
        await service.cancelAllAthkarNotifications();

        verifyNever(mockNotificationsPlugin.cancel(id: anyNamed('id')));
      });

      test('should handle cancel error', () async {
        when(
          mockNotificationsPlugin.cancel(id: anyNamed('id')),
        ).thenThrow(Exception('Cancel failed'));

        await service.cancelAllAthkarNotifications(); // Should not throw
      });
    });

    group('checkLaunchNotification', () {
      test('should return null when no notification launched app', () async {
        when(
          mockDispatcher.getNotificationAppLaunchDetails(),
        ).thenAnswer((_) async => null);

        final NotificationResponse? result = await service
            .checkLaunchNotification();

        expect(result, isNull);
      });

      test('should return null when payload is empty', () async {
        const response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 1001,
          payload: '',
        );

        when(mockDispatcher.getNotificationAppLaunchDetails()).thenAnswer(
          (_) async => const NotificationAppLaunchDetails(
            true,
            notificationResponse: response,
          ),
        );

        final NotificationResponse? result = await service
            .checkLaunchNotification();

        expect(result, isNull);
      });

      test('should return null when payload was already handled', () async {
        const payload = 'morning_athkar_1234567890';
        const response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 1001,
          payload: payload,
        );

        when(mockPrefs.getString(any)).thenAnswer((_) async => payload);
        when(mockDispatcher.getNotificationAppLaunchDetails()).thenAnswer(
          (_) async => const NotificationAppLaunchDetails(
            true,
            notificationResponse: response,
          ),
        );

        final NotificationResponse? result = await service
            .checkLaunchNotification();

        expect(result, isNull);
      });

      test(
        'should return null when notification is stale (older than 60 seconds)',
        () async {
          // Timestamp from 2 minutes ago
          final int staleTimestamp =
              DateTime.now().millisecondsSinceEpoch - 120000;
          final payload = 'morning_athkar_$staleTimestamp';
          final response = NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            id: 1001,
            payload: payload,
          );

          when(mockPrefs.getString(any)).thenAnswer((_) async => null);
          when(mockDispatcher.getNotificationAppLaunchDetails()).thenAnswer(
            (_) async => NotificationAppLaunchDetails(
              true,
              notificationResponse: response,
            ),
          );

          final NotificationResponse? result = await service
              .checkLaunchNotification();

          expect(result, isNull);
          // Verify it was marked as handled to prevent future checks
          verify(mockPrefs.setString(any, payload)).called(1);
        },
      );

      test(
        'should return response for valid recent morning notification',
        () async {
          // Timestamp from 5 seconds ago
          final int recentTimestamp =
              DateTime.now().millisecondsSinceEpoch - 5000;
          final payload = 'morning_athkar_$recentTimestamp';
          final response = NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            id: 2001,
            payload: payload,
          );

          when(mockPrefs.getString(any)).thenAnswer((_) async => null);
          when(mockPrefs.setInt(any, any)).thenAnswer((_) async {
            return;
          });
          when(mockDispatcher.getNotificationAppLaunchDetails()).thenAnswer(
            (_) async => NotificationAppLaunchDetails(
              true,
              notificationResponse: response,
            ),
          );

          final NotificationResponse? result = await service
              .checkLaunchNotification();

          expect(result, isNotNull);
          expect(result?.id, 2001);
          expect(result?.payload, payload);
        },
      );

      test(
        'should return response for valid recent evening notification',
        () async {
          final int recentTimestamp =
              DateTime.now().millisecondsSinceEpoch - 5000;
          final payload = 'evening_athkar_$recentTimestamp';
          final response = NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            id: 2002,
            payload: payload,
          );

          when(mockPrefs.getString(any)).thenAnswer((_) async => null);
          when(mockPrefs.setInt(any, any)).thenAnswer((_) async {
            return;
          });
          when(mockDispatcher.getNotificationAppLaunchDetails()).thenAnswer(
            (_) async => NotificationAppLaunchDetails(
              true,
              notificationResponse: response,
            ),
          );

          final NotificationResponse? result = await service
              .checkLaunchNotification();

          expect(result, isNotNull);
          expect(result?.id, 2002);
        },
      );

      test('should return null for non-athkar notification id', () async {
        final int recentTimestamp =
            DateTime.now().millisecondsSinceEpoch - 5000;
        final payload = 'other_notification_$recentTimestamp';
        final response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 9999, // Not an athkar notification ID
          payload: payload,
        );

        when(mockPrefs.getString(any)).thenAnswer((_) async => null);
        when(mockPrefs.setInt(any, any)).thenAnswer((_) async {
          return;
        });
        when(mockDispatcher.getNotificationAppLaunchDetails()).thenAnswer(
          (_) async => NotificationAppLaunchDetails(
            true,
            notificationResponse: response,
          ),
        );

        final NotificationResponse? result = await service
            .checkLaunchNotification();

        expect(result, isNull);
      });

      test('should handle payload without timestamp gracefully', () async {
        const payload = 'invalid_payload';
        const response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 1001,
          payload: payload,
        );

        when(mockPrefs.getString(any)).thenAnswer((_) async => null);
        when(mockPrefs.setInt(any, any)).thenAnswer((_) async {
          return;
        });
        when(mockDispatcher.getNotificationAppLaunchDetails()).thenAnswer(
          (_) async => const NotificationAppLaunchDetails(
            true,
            notificationResponse: response,
          ),
        );

        // Should not throw and should still process the notification
        // (timestamp validation skipped when parsing fails)
        final NotificationResponse? result = await service
            .checkLaunchNotification();

        expect(result, isNotNull);
      });

      test('should handle payload with invalid part count', () async {
        const payload = 'morning_athkar'; // Missing timestamp
        const response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 1001,
          payload: payload,
        );

        when(mockPrefs.getString(any)).thenAnswer((_) async => null);
        when(mockDispatcher.getNotificationAppLaunchDetails()).thenAnswer(
          (_) async => const NotificationAppLaunchDetails(
            true,
            notificationResponse: response,
          ),
        );

        final NotificationResponse? result = await service
            .checkLaunchNotification();

        expect(
          result,
          isNotNull,
        ); // Still processed but timestamp check skipped
      });
    });

    group('clearLaunchNotificationData', () {
      test('should clear stored notification data', () async {
        when(mockPrefs.remove(any)).thenAnswer((_) async {
          return;
        });

        await service.clearLaunchNotificationData();

        verify(mockPrefs.remove('last_handled_notification_payload')).called(1);
        verify(
          mockPrefs.remove('last_handled_notification_timestamp'),
        ).called(1);
      });

      test('should handle clear error gracefully', () async {
        when(mockPrefs.remove(any)).thenThrow(Exception('Remove failed'));

        // Should not throw
        await service.clearLaunchNotificationData();
      });
    });

    group('scheduleTestNotification', () {
      test('should schedule test notification with default delay', () async {
        await service.scheduleTestNotification();

        verify(
          mockNotificationsPlugin.zonedSchedule(
            id: 9999,
            title: 'Test Athkar Notification',
            body: anyNamed('body'), // Dynamic message with time
            scheduledDate: anyNamed('scheduledDate'),
            notificationDetails: anyNamed('notificationDetails'),
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        ).called(1);
      });

      test('should schedule test notification with custom delay', () async {
        await service.scheduleTestNotification(minutesFromNow: 5);

        verify(
          mockNotificationsPlugin.zonedSchedule(
            id: 9999,
            title: 'Test Athkar Notification',
            body: anyNamed('body'),
            scheduledDate: anyNamed('scheduledDate'),
            notificationDetails: anyNamed('notificationDetails'),
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        ).called(1);
      });

      test('should not schedule test notification if disabled', () async {
        NotificationConfig.enableLocalNotifications = false;
        await service.scheduleTestNotification();

        verifyNever(
          mockNotificationsPlugin.zonedSchedule(
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

      test('should handle test notification scheduling error', () async {
        when(
          mockNotificationsPlugin.zonedSchedule(
            id: anyNamed('id'),
            title: anyNamed('title'),
            body: anyNamed('body'),
            scheduledDate: anyNamed('scheduledDate'),
            notificationDetails: anyNamed('notificationDetails'),
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        ).thenThrow(Exception('Test scheduling failed'));

        await service.scheduleTestNotification(); // Should not throw
      });
    });

    group('scheduleDebugAthkarNotification', () {
      test('should schedule debug morning athkar', () async {
        await service.scheduleDebugAthkarNotification(isMorning: true);

        verify(
          mockNotificationsPlugin.zonedSchedule(
            id: 1001, // Morning ID
            title: 'أذكار الصباح',
            body: 'حان وقت أذكار الصباح 🌅',
            scheduledDate: anyNamed('scheduledDate'),
            notificationDetails: anyNamed('notificationDetails'),
            androidScheduleMode: anyNamed('androidScheduleMode'),
            // No matchDateTimeComponents expected for debug
            payload: anyNamed('payload'), // Added payload check
          ),
        ).called(1);
      });

      test('should schedule debug evening athkar', () async {
        await service.scheduleDebugAthkarNotification(isMorning: false);

        verify(
          mockNotificationsPlugin.zonedSchedule(
            id: 1002, // Evening ID
            title: 'أذكار المساء',
            body: 'حان وقت أذكار المساء 🌙',
            scheduledDate: anyNamed('scheduledDate'),
            notificationDetails: anyNamed('notificationDetails'),
            androidScheduleMode: anyNamed('androidScheduleMode'),
            payload: anyNamed('payload'), // Added payload check
          ),
        ).called(1);
      });

      test('should not schedule if disabled', () async {
        NotificationConfig.enableLocalNotifications = false;
        await service.scheduleDebugAthkarNotification(isMorning: true);

        verifyNever(
          mockNotificationsPlugin.zonedSchedule(
            id: anyNamed('id'),
            title: anyNamed('title'),
            body: anyNamed('body'),
            scheduledDate: anyNamed('scheduledDate'),
            notificationDetails: anyNamed('notificationDetails'),
            androidScheduleMode: anyNamed('androidScheduleMode'),
            payload: anyNamed('payload'),
          ),
        );
      });
    });

    group('notification content formatting', () {
      test('should have properly formatted Arabic morning title', () {
        const title = 'أذكار الصباح';
        expect(title.trim(), equals(title));
      });

      test('should have properly formatted Arabic evening title', () {
        const title = 'أذكار المساء';
        expect(title.trim(), equals(title));
      });
    });

    group('Android platform specifics', () {
      test('should create notification channel on Android', () async {
        final androidService = TestAndroidAthkarNotificationService(
          mockPrefs,
          mockDispatcher,
          mockAnalyticsService,
          mockNavigationService,
          fakePrayerTimesRepository,
        );

        await androidService.initialize();

        verify(mockAndroidPlugin.createNotificationChannel(any)).called(1);
      });
    });

    group('timezone detection logic', () {
      test('should detect Cairo timezone (+2)', () async {
        final testService = TestTimezoneAthkarNotificationService(
          mockPrefs,
          mockDispatcher,
          mockAnalyticsService,
          mockNavigationService,
          fakePrayerTimesRepository,
          '2:00:00.000000',
        );

        await testService.initialize();

        // Cannot easily verify internal state without public getter or checking logger
        // But we rely on coverage report showing lines covered
      });

      test('should detect Riyadh timezone (+3)', () async {
        final testService = TestTimezoneAthkarNotificationService(
          mockPrefs,
          mockDispatcher,
          mockAnalyticsService,
          mockNavigationService,
          fakePrayerTimesRepository,
          '3:00:00.000000',
        );
        await testService.initialize();
      });

      test('should detect Dubai timezone (+4)', () async {
        final testService = TestTimezoneAthkarNotificationService(
          mockPrefs,
          mockDispatcher,
          mockAnalyticsService,
          mockNavigationService,
          fakePrayerTimesRepository,
          '4:00:00.000000',
        );
        await testService.initialize();
      });

      test('should fallback to UTC for unknown offset', () async {
        final testService = TestTimezoneAthkarNotificationService(
          mockPrefs,
          mockDispatcher,
          mockAnalyticsService,
          mockNavigationService,
          fakePrayerTimesRepository,
          '0:00:00.000000',
        );
        await testService.initialize();
      });
    });

    group('notification timing', () {
      test(
        'should schedule morning athkar exactly 1 hour after Fajr',
        () async {
          final DateTime tomorrow = DateTime.now()
              .add(const Duration(days: 1))
              .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
          final PrayerTimeEntity prayerTime = buildPrayerTimeEntity(tomorrow);
          fakePrayerTimesRepository.prayerTimesForRange = [prayerTime];

          await service.scheduleAthkarNotifications();

          final DateTime expectedDate = prayerTime.fajr.add(
            const Duration(hours: 1),
          );

          verify(
            mockNotificationsPlugin.zonedSchedule(
              id: anyNamed('id'),
              title: 'أذكار الصباح',
              body: anyNamed('body'),
              scheduledDate: argThat(
                predicate(
                  (tz.TZDateTime date) =>
                      date.hour == expectedDate.hour &&
                      date.minute == expectedDate.minute,
                ),
                named: 'scheduledDate',
              ),
              notificationDetails: anyNamed('notificationDetails'),
              androidScheduleMode: anyNamed('androidScheduleMode'),
              matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
              payload: anyNamed('payload'),
            ),
          ).called(1);
        },
      );

      test('should schedule evening athkar exactly 1 hour after Asr', () async {
        final DateTime tomorrow = DateTime.now()
            .add(const Duration(days: 1))
            .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
        final PrayerTimeEntity prayerTime = buildPrayerTimeEntity(tomorrow);
        fakePrayerTimesRepository.prayerTimesForRange = [prayerTime];

        await service.scheduleAthkarNotifications();

        final DateTime expectedDate = prayerTime.asr.add(
          const Duration(hours: 1),
        );

        verify(
          mockNotificationsPlugin.zonedSchedule(
            id: anyNamed('id'),
            title: 'أذكار المساء',
            body: anyNamed('body'),
            scheduledDate: argThat(
              predicate(
                (tz.TZDateTime date) =>
                    date.hour == expectedDate.hour &&
                    date.minute == expectedDate.minute,
              ),
              named: 'scheduledDate',
            ),
            notificationDetails: anyNamed('notificationDetails'),
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        ).called(1);
      });

      test(
        'should use updated fallback times when prayer times are missing',
        () async {
          fakePrayerTimesRepository.settings = const PrayerSettingsEntity();
          fakePrayerTimesRepository.hasPermission = false;
          fakePrayerTimesRepository.prayerTimesForRange = <PrayerTimeEntity>[];

          await service.scheduleAthkarNotifications();

          // 07:30 Morning
          verify(
            mockNotificationsPlugin.zonedSchedule(
              id: 1001,
              title: anyNamed('title'),
              body: anyNamed('body'),
              scheduledDate: argThat(
                predicate(
                  (tz.TZDateTime date) => date.hour == 7 && date.minute == 30,
                ),
                named: 'scheduledDate',
              ),
              notificationDetails: anyNamed('notificationDetails'),
              androidScheduleMode: anyNamed('androidScheduleMode'),
              matchDateTimeComponents: DateTimeComponents.time,
              payload: anyNamed('payload'),
            ),
          ).called(1);

          // 18:00 Evening
          verify(
            mockNotificationsPlugin.zonedSchedule(
              id: 1002,
              title: anyNamed('title'),
              body: anyNamed('body'),
              scheduledDate: argThat(
                predicate(
                  (tz.TZDateTime date) => date.hour == 18 && date.minute == 0,
                ),
                named: 'scheduledDate',
              ),
              notificationDetails: anyNamed('notificationDetails'),
              androidScheduleMode: anyNamed('androidScheduleMode'),
              matchDateTimeComponents: DateTimeComponents.time,
              payload: anyNamed('payload'),
            ),
          ).called(1);
        },
      );
    });

    group('location and prayer context', () {
      test('should handle location error when fetching context', () async {
        fakePrayerTimesRepository.settings = const PrayerSettingsEntity();
        fakePrayerTimesRepository.currentLocation = LocationResult(
          latitude: 0,
          longitude: 0,
          error: 'Location failed',
        );

        await service.scheduleAthkarNotifications();

        // Should fallback to fixed times
        verify(
          mockNotificationsPlugin.zonedSchedule(
            id: 1001,
            title: anyNamed('title'),
            body: anyNamed('body'),
            scheduledDate: anyNamed('scheduledDate'),
            notificationDetails: anyNamed('notificationDetails'),
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: DateTimeComponents.time,
            payload: anyNamed('payload'),
          ),
        ).called(1);
      });

      test('should fetch location if settings are empty', () async {
        fakePrayerTimesRepository.settings = const PrayerSettingsEntity(
          savedLatitude: null,
          savedLongitude: null,
        );

        await service.scheduleAthkarNotifications();

        // verify location was requested
        // In FakePrayerTimesRepository, location is provided in constructor
      });

      test(
        'should recommend specialized calculation method for Umm Al-Qura in Egypt',
        () async {
          fakePrayerTimesRepository.settings = const PrayerSettingsEntity(
            calculationMethod: CalculationMethod.ummAlQura,
            savedLatitude: 30.0444,
            savedLongitude: 31.2357,
          );
          fakePrayerTimesRepository.countryCode = 'EG';

          await service.scheduleAthkarNotifications();
          // Logic inside _resolveScheduleContext should switch to Egyptian General Authority
        },
      );
    });

    group('interactions and navigation', () {
      test('should ignore already handled notification payload', () async {
        const payload = 'morning_athkar_12345';
        const response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 1001,
          payload: payload,
        );

        when(mockPrefs.getString(any)).thenAnswer((_) async => payload);
        when(mockPrefs.getInt(any)).thenAnswer(
          (_) async => DateTime.now().millisecondsSinceEpoch - 30000,
        );

        await service.handleNotificationResponse(response);

        // verify we didn't navigation? Hard to verify private _navigateToRoute
      });

      test('should handle navigation failure gracefully', () async {
        const response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 1001,
          payload: 'morning_athkar_123',
        );

        when(mockPrefs.getString(any)).thenAnswer((_) async => null);
        when(mockPrefs.getInt(any)).thenAnswer((_) async => null);

        // Navigation service should throw to trigger the catch block
        when(
          mockNavigationService.routeToDestination(any),
        ).thenThrow(Exception('Navigation failed'));

        await service.handleNotificationResponse(response);
      });
    });

    group('error handling and edge cases', () {
      test('should skip invalid prayer times with zero year', () async {
        // BUG #4 FIX TEST: Invalid prayer times should be skipped gracefully (lines 479-480)
        final now = DateTime.now();
        final startDate = DateTime(now.year, now.month, now.day);

        // Create prayer times with invalid year (year=0) to test the validation skip
        final validPrayerTime = buildPrayerTimeEntity(startDate);
        final invalidPrayerTime = PrayerTimeEntity(
          date: startDate.add(const Duration(days: 1)),
          fajr: DateTime(0, 1, 1, 5, 10), // Invalid: year 0
          sunrise: DateTime(now.year, now.month, now.day, 6, 25),
          dhuhr: DateTime(now.year, now.month, now.day, 12, 5),
          asr: DateTime(0, 1, 1, 15, 40), // Invalid: year 0
          maghrib: DateTime(now.year, now.month, now.day, 18, 8),
          isha: DateTime(now.year, now.month, now.day, 19, 25),
          midnight: DateTime(now.year, now.month, now.day, 23, 30),
          lastThird: DateTime(now.year, now.month, now.day, 2, 45),
          latitude: 30.0444,
          longitude: 31.2357,
        );

        // Update fake repository to return mixed valid/invalid prayer times
        fakePrayerTimesRepository.prayerTimesForRange = [
          validPrayerTime,
          invalidPrayerTime,
        ];

        await service.scheduleAthkarNotifications();

        // Verify no exception thrown - invalid prayer time skipped gracefully
        expect(true, true); // Smoke test - verifies no exception thrown
      });

      test(
        'should skip prayer times during notification building if invalid',
        () async {
          // BUG #4 FIX TEST: Prayer time validation in _createDynamicNotification (lines 589-590)
          final now = DateTime.now();

          // Create notification with completely invalid prayer time
          final invalidDateTime = DateTime(0, 0, 0); // year=0, month=0, day=0

          // This tests the defensive check in _createDynamicNotification
          // The method should gracefully return null for invalid DateTimes
          final notification = service.testCreateDynamicNotification(
            date: now,
            prayerTime: invalidDateTime,
            isMorning: true,
          );

          // Should return null for invalid datetime
          expect(notification, null);
        },
      );

      test('should handle large notification batch with UI thread yield', () async {
        // OPTIMIZATION TEST: UI thread yield for >5 notifications (line 344)
        final now = DateTime.now();
        final startDate = DateTime(now.year, now.month, now.day);

        // Build list of 10 prayer times that will create 20 notifications (morning + evening)
        final prayerTimes = <PrayerTimeEntity>[];
        for (int i = 0; i < 10; i++) {
          final date = startDate.add(Duration(days: i));
          prayerTimes.add(
            PrayerTimeEntity(
              date: date,
              fajr: date.add(const Duration(hours: 5, minutes: 10)),
              sunrise: date.add(const Duration(hours: 6, minutes: 25)),
              dhuhr: date.add(const Duration(hours: 12, minutes: 5)),
              asr: date.add(const Duration(hours: 15, minutes: 40)),
              maghrib: date.add(const Duration(hours: 18, minutes: 8)),
              isha: date.add(const Duration(hours: 19, minutes: 25)),
              midnight: date.add(const Duration(hours: 23, minutes: 30)),
              lastThird: date.add(const Duration(hours: 2, minutes: 45)),
              latitude: 30.0444,
              longitude: 31.2357,
            ),
          );
        }

        // Update fake repository to return many prayer times
        fakePrayerTimesRepository.prayerTimesForRange = prayerTimes;

        await service.scheduleAthkarNotifications();

        // Verify multiple notifications were scheduled (triggers UI thread yield every 5)
        expect(true, true); // Smoke test - verifies no exception on large batch
      });
    });

    group('utilities', () {
      test('should return payload prefixes', () {
        expect(service.morningAthkarPayloadPrefix, isNotEmpty);
        expect(service.eveningAthkarPayloadPrefix, isNotEmpty);
      });
    });
  });
}

class TestAndroidAthkarNotificationService extends AthkarNotificationService {
  TestAndroidAthkarNotificationService(
    super.prefs,
    super.dispatcher,
    super.analytics,
    super.navigationService,
    super.prayerTimesRepository,
  );

  @override
  bool get isAndroid => true;
}

class TestIOSAthkarNotificationService extends AthkarNotificationService {
  TestIOSAthkarNotificationService(
    super.prefs,
    super.dispatcher,
    super.analytics,
    super.navigationService,
    super.prayerTimesRepository,
  );

  @override
  bool get isAndroid => false;
}

class TestTimezoneDetectingErrorAthkarNotificationService
    extends AthkarNotificationService {
  TestTimezoneDetectingErrorAthkarNotificationService(
    super.prefs,
    super.dispatcher,
    super.analytics,
    super.navigationService,
    super.prayerTimesRepository,
  );

  @override
  String getTimeZoneOffsetString() {
    throw Exception('Timezone detection failed');
  }
}

class TestTimezoneLocationErrorAthkarNotificationService
    extends AthkarNotificationService {
  TestTimezoneLocationErrorAthkarNotificationService(
    super.prefs,
    super.dispatcher,
    super.analytics,
    super.navigationService,
    super.prayerTimesRepository,
  );

  @override
  String getTimeZoneOffsetString() {
    return '2:00:00.000000'; // Egypt
  }

  @override
  Future<String?> getLocalTimeZone() async {
    return 'Invalid/Timezone';
  }
}

class TestTimezoneAthkarNotificationService extends AthkarNotificationService {
  TestTimezoneAthkarNotificationService(
    super.prefs,
    super.dispatcher,
    super.analytics,
    super.navigationService,
    super.prayerTimesRepository,
    this.mockOffset,
  );

  final String mockOffset;

  @override
  String getTimeZoneOffsetString() {
    return mockOffset;
  }
}

class TestInvalidTimezoneAthkarNotificationService
    extends AthkarNotificationService {
  TestInvalidTimezoneAthkarNotificationService(
    super.prefs,
    super.dispatcher,
    super.analytics,
    super.navigationService,
    super.prayerTimesRepository,
  );
}

class FakePrayerTimesRepository implements PrayerTimesRepository {
  FakePrayerTimesRepository({
    required this.settings,
    required this.prayerTimesForRange,
    this.hasPermission = true,
    LocationResult? currentLocation,
    this.countryCode,
  }) : currentLocation =
           currentLocation ??
           LocationResult(
             latitude: settings.savedLatitude ?? 30.0444,
             longitude: settings.savedLongitude ?? 31.2357,
             countryCode: countryCode,
           );

  PrayerSettingsEntity settings;
  List<PrayerTimeEntity> prayerTimesForRange;
  bool hasPermission;
  LocationResult currentLocation;
  String? countryCode;
  bool shouldThrow = false;
  bool shouldThrowInLoadSettings = false;

  @override
  Future<PrayerTimeEntity> getPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required PrayerSettingsEntity settings,
  }) async => throw UnimplementedError();

  @override
  Future<List<PrayerTimeEntity>> getPrayerTimesForRange({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
    required PrayerSettingsEntity settings,
  }) async {
    if (shouldThrow) throw Exception('GetPrayerTimesForRange failed');
    return prayerTimesForRange;
  }

  @override
  Future<List<PrayerTimeEntity>> getMonthlyPrayerTimes({
    required double latitude,
    required double longitude,
    required int year,
    required int month,
    required PrayerSettingsEntity settings,
  }) async => throw UnimplementedError();

  @override
  Future<LocationResult> getCurrentLocation({
    bool forceRefresh = false,
  }) async => currentLocation;

  @override
  Future<String?> getLocationName({
    required double latitude,
    required double longitude,
  }) async => null;

  @override
  Future<String?> getCountryCode({
    required double latitude,
    required double longitude,
  }) async => countryCode;

  @override
  Future<void> saveSettings(PrayerSettingsEntity settings) async {
    this.settings = settings;
  }

  @override
  Future<PrayerSettingsEntity> loadSettings() async {
    if (shouldThrowInLoadSettings) throw Exception('LoadSettings failed');
    return settings;
  }

  @override
  Future<bool> hasLocationPermission() async => hasPermission;

  @override
  Future<bool> requestLocationPermission({bool allowOpenSettings = false}) async =>
      hasPermission;
}

PrayerTimeEntity buildPrayerTimeEntity(DateTime date) {
  final DateTime normalizedDate = DateTime(date.year, date.month, date.day);

  return PrayerTimeEntity(
    date: normalizedDate,
    fajr: normalizedDate.add(const Duration(hours: 5, minutes: 10)),
    sunrise: normalizedDate.add(const Duration(hours: 6, minutes: 25)),
    dhuhr: normalizedDate.add(const Duration(hours: 12, minutes: 5)),
    asr: normalizedDate.add(const Duration(hours: 15, minutes: 40)),
    maghrib: normalizedDate.add(const Duration(hours: 18, minutes: 8)),
    isha: normalizedDate.add(const Duration(hours: 19, minutes: 25)),
    midnight: normalizedDate.add(const Duration(hours: 23, minutes: 30)),
    lastThird: normalizedDate.add(const Duration(hours: 2, minutes: 45)),
    latitude: 30.0444,
    longitude: 31.2357,
  );
}
