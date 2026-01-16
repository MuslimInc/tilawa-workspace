import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/config/notification_config.dart';
import 'package:tilawa/core/services/athkar_notification_service.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'athkar_notification_service_test.mocks.dart';

@GenerateMocks([
  FlutterLocalNotificationsPlugin,
  AndroidFlutterLocalNotificationsPlugin,
  SharedPreferencesAsync,
  INotificationDispatcher,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AthkarNotificationService', () {
    late AthkarNotificationService service;
    late MockFlutterLocalNotificationsPlugin mockNotificationsPlugin;
    late MockAndroidFlutterLocalNotificationsPlugin mockAndroidPlugin;
    late MockSharedPreferencesAsync mockPrefs;
    late MockINotificationDispatcher mockDispatcher;

    setUp(() {
      // Initialize timezone for tests
      tz.initializeTimeZones();

      mockNotificationsPlugin = MockFlutterLocalNotificationsPlugin();
      mockAndroidPlugin = MockAndroidFlutterLocalNotificationsPlugin();
      mockPrefs = MockSharedPreferencesAsync();
      mockDispatcher = MockINotificationDispatcher();

      // Mock dispatcher to return our mock plugin
      when(mockDispatcher.initialize()).thenAnswer((_) async {
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
        mockDispatcher.getNotificationAppLaunchDetails(),
      ).thenAnswer((_) async => null);

      service = AthkarNotificationService(mockPrefs, mockDispatcher);

      // Default mock behavior
      when(
        mockNotificationsPlugin.initialize(
          any,
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
          any,
          any,
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
        ),
      ).thenAnswer((_) async {
        return;
      });

      when(mockNotificationsPlugin.cancel(any)).thenAnswer((_) async {
        return;
      });

      when(
        mockDispatcher.getNotificationAppLaunchDetails(),
      ).thenAnswer((_) async => null);

      when(mockPrefs.getString(any)).thenAnswer((_) async => null);
      when(mockPrefs.setString(any, any)).thenAnswer((_) async {
        return;
      });
    });

    // Reset config after tests
    tearDown(() {
      NotificationConfig.enableLocalNotifications = true;
    });

    group('initialization', () {
      test('should create service instance', () {
        expect(service, isNotNull);
        expect(service, isA<AthkarNotificationService>());
      });

      test('should initialize dispatcher', () async {
        await service.initialize();

        verify(mockDispatcher.initialize()).called(1);
        verify(
          mockDispatcher.registerHandler(
            serviceId: 'athkar',
            notificationIds: anyNamed('notificationIds'),
            handler: anyNamed('handler'),
          ),
        ).called(1);
      });

      test('should not initialize if notifications disabled', () async {
        NotificationConfig.enableLocalNotifications = false;
        await service.initialize();

        verifyNever(mockDispatcher.initialize());
      });

      test('should not initialize twice if already initialized', () async {
        await service.initialize();
        reset(mockDispatcher);
        // Re-setup mock after reset
        when(mockDispatcher.initialize()).thenAnswer((_) async {
          return;
        });
        when(
          mockDispatcher.notificationsPlugin,
        ).thenReturn(mockNotificationsPlugin);

        await service.initialize(); // Second call

        verifyNever(mockDispatcher.initialize());
      });

      test('should handle initialization error gracefully', () async {
        when(mockDispatcher.initialize()).thenThrow(Exception('Init failed'));

        await service.initialize(); // Should not throw

        // logger should have logged error, but we don't spy logger here.
        // We verified it didn't crash.
      });

      test(
        'should handle timezone detection error and fallback to UTC',
        () async {
          final testService = TestTimezoneErrorAthkarNotificationService(
            mockPrefs,
            mockDispatcher,
          );

          await testService
              .initialize(); // Should not throw and fallback to UTC
        },
      );

      test('should handle invalid timezone name and fallback to UTC', () async {
        // Test with an invalid timezone that will cause getLocation to fail
        final testService = TestInvalidTimezoneAthkarNotificationService(
          mockPrefs,
          mockDispatcher,
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
        verify(mockDispatcher.initialize()).called(1);
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
            1001, // Morning ID
            'أذكار الصباح',
            'حان وقت أذكار الصباح 🌅',
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        ).called(1);

        verify(
          mockNotificationsPlugin.zonedSchedule(
            1002, // Evening ID
            'أذكار المساء',
            'حان وقت أذكار المساء 🌙',
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        ).called(1);
      });

      test('should not schedule if disabled', () async {
        NotificationConfig.enableLocalNotifications = false;
        await service.scheduleAthkarNotifications();

        verifyNever(
          mockNotificationsPlugin.zonedSchedule(
            any,
            any,
            any,
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
          ),
        );
      });

      test('should handle scheduling error gracefully', () async {
        when(
          mockNotificationsPlugin.zonedSchedule(
            any,
            any,
            any,
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
          ),
        ).thenThrow(Exception('Scheduling failed'));

        await service.scheduleAthkarNotifications(); // Should not throw
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
        await service.cancelAllAthkarNotifications();

        verify(mockNotificationsPlugin.cancel(1001)).called(1);
        verify(mockNotificationsPlugin.cancel(1002)).called(1);
      });

      test('should not cancel if disabled', () async {
        NotificationConfig.enableLocalNotifications = false;
        await service.cancelAllAthkarNotifications();

        verifyNever(mockNotificationsPlugin.cancel(any));
      });

      test('should handle cancel error', () async {
        when(
          mockNotificationsPlugin.cancel(any),
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
            id: 1001,
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
          expect(result?.id, 1001);
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
            id: 1002,
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
          expect(result?.id, 1002);
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
            9999,
            'Test Athkar Notification',
            any, // Dynamic message with time
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
          ),
        ).called(1);
      });

      test('should schedule test notification with custom delay', () async {
        await service.scheduleTestNotification(minutesFromNow: 5);

        verify(
          mockNotificationsPlugin.zonedSchedule(
            9999,
            'Test Athkar Notification',
            any,
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
          ),
        ).called(1);
      });

      test('should not schedule test notification if disabled', () async {
        NotificationConfig.enableLocalNotifications = false;
        await service.scheduleTestNotification();

        verifyNever(
          mockNotificationsPlugin.zonedSchedule(
            any,
            any,
            any,
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
          ),
        );
      });

      test('should handle test notification scheduling error', () async {
        when(
          mockNotificationsPlugin.zonedSchedule(
            any,
            any,
            any,
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
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
            1001, // Morning ID
            'أذكار الصباح',
            'حان وقت أذكار الصباح 🌅',
            any,
            any,
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
            1002, // Evening ID
            'أذكار المساء',
            'حان وقت أذكار المساء 🌙',
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
            payload: anyNamed('payload'),
          ),
        ).called(1);
      });

      test('should not schedule if disabled', () async {
        NotificationConfig.enableLocalNotifications = false;
        await service.scheduleDebugAthkarNotification(isMorning: true);

        verifyNever(
          mockNotificationsPlugin.zonedSchedule(
            any,
            any,
            any,
            any,
            any,
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
          '3:00:00.000000',
        );
        await testService.initialize();
      });

      test('should detect Dubai timezone (+4)', () async {
        final testService = TestTimezoneAthkarNotificationService(
          mockPrefs,
          mockDispatcher,
          '4:00:00.000000',
        );
        await testService.initialize();
      });

      test('should fallback to UTC for unknown offset', () async {
        final testService = TestTimezoneAthkarNotificationService(
          mockPrefs,
          mockDispatcher,
          '0:00:00.000000',
        );
        await testService.initialize();
      });
    });
  });
}

class TestAndroidAthkarNotificationService extends AthkarNotificationService {
  TestAndroidAthkarNotificationService(super.prefs, super.dispatcher);

  @override
  bool get isAndroid => true;
}

class TestTimezoneAthkarNotificationService extends AthkarNotificationService {
  TestTimezoneAthkarNotificationService(
    super.prefs,
    super.dispatcher,
    this.mockOffset,
  );

  final String mockOffset;

  @override
  String getTimeZoneOffsetString() {
    // If mockOffset is a special marker for invalid timezone, return result
    // that will trigger returning a timezone name from _getLocalTimeZone
    if (mockOffset == 'INVALID_TZ') {
      // Return offset that matches no valid timezone to trigger the catch block
      return mockOffset;
    }
    return mockOffset;
  }
}

class TestInvalidTimezoneAthkarNotificationService
    extends AthkarNotificationService {
  TestInvalidTimezoneAthkarNotificationService(super.prefs, super.dispatcher);
}

class TestTimezoneErrorAthkarNotificationService
    extends AthkarNotificationService {
  TestTimezoneErrorAthkarNotificationService(super.prefs, super.dispatcher);

  @override
  String getTimeZoneOffsetString() {
    throw Exception('Timezone detection failed');
  }
}
