import 'dart:convert';
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:tilawa/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:tilawa/features/notifications/presentation/services/fcm_notification_handler_service.dart';
import 'package:tilawa/features/auth/domain/services/device_revoked_notifier.dart';
import 'package:tilawa/features/auth/domain/services/session_revoked_notifier.dart';
import 'package:tilawa/features/quran_sessions/domain/services/session_taken_over_notifier.dart';
import 'package:tilawa/features/settings/domain/services/teacher_capability_refresh_notifier.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

class MockNotificationsRemoteDataSource extends Mock
    implements NotificationsRemoteDataSource {}

class MockNotificationSettings extends Mock implements NotificationSettings {}

class MockINotificationDispatcher extends Mock
    implements INotificationDispatcher {}

class MockFCMNotificationHandlerService extends Mock
    implements FCMNotificationHandlerService {}

class MockLogger extends Mock implements Logger {}

class MockTeacherCapabilityRefreshNotifier extends Mock
    implements TeacherCapabilityRefreshNotifier {}

class MockSessionRevokedNotifier extends Mock
    implements SessionRevokedNotifier {}

class MockSessionTakenOverNotifier extends Mock
    implements SessionTakenOverNotifier {}

class MockDeviceRevokedNotifier extends Mock implements DeviceRevokedNotifier {}

class _FallbackRemoteMessage extends Fake implements RemoteMessage {}

void main() {
  late NotificationsRepositoryImpl repository;
  late MockNotificationsRemoteDataSource mockRemoteDataSource;
  late MockINotificationDispatcher mockDispatcher;
  late MockFCMNotificationHandlerService mockFcmHandlerService;
  late MockLogger mockLogger;
  late MockTeacherCapabilityRefreshNotifier
  mockTeacherCapabilityRefreshNotifier;
  late MockSessionRevokedNotifier mockSessionRevokedNotifier;
  late MockSessionTakenOverNotifier mockSessionTakenOverNotifier;
  late MockDeviceRevokedNotifier mockDeviceRevokedNotifier;

  setUpAll(() {
    registerFallbackValue(_FallbackRemoteMessage());
  });

  setUp(() {
    mockRemoteDataSource = MockNotificationsRemoteDataSource();
    mockDispatcher = MockINotificationDispatcher();
    mockFcmHandlerService = MockFCMNotificationHandlerService();
    mockLogger = MockLogger();
    mockTeacherCapabilityRefreshNotifier =
        MockTeacherCapabilityRefreshNotifier();
    mockSessionRevokedNotifier = MockSessionRevokedNotifier();
    mockSessionTakenOverNotifier = MockSessionTakenOverNotifier();
    mockDeviceRevokedNotifier = MockDeviceRevokedNotifier();

    when(
      () => mockLogger.d(
        any(),
        error: any(named: 'error'),
      ),
    ).thenReturn(null);
    when(
      () => mockLogger.e(
        any(),
        error: any(named: 'error'),
      ),
    ).thenReturn(null);

    repository = NotificationsRepositoryImpl(
      mockRemoteDataSource,
      mockDispatcher,
      mockFcmHandlerService,
      mockLogger,
      mockTeacherCapabilityRefreshNotifier,
      mockSessionRevokedNotifier,
      mockSessionTakenOverNotifier,
      mockDeviceRevokedNotifier,
    );
  });

  group('requestPermission', () {
    test('calls requestPermission on the remote data source', () async {
      final settings = MockNotificationSettings();
      when(
        () => settings.authorizationStatus,
      ).thenReturn(AuthorizationStatus.authorized);
      when(
        () => mockRemoteDataSource.requestPermission(),
      ).thenAnswer((_) async => settings);

      await repository.requestPermission();

      verify(() => mockRemoteDataSource.requestPermission()).called(1);
    });
  });

  group('getToken', () {
    test('returns token from the remote data source', () async {
      when(
        () => mockRemoteDataSource.getToken(),
      ).thenAnswer((_) async => 'test_token');

      final result = await repository.getToken();

      expect(result, 'test_token');
      verify(() => mockRemoteDataSource.getToken()).called(1);
    });

    test('returns null when token lookup throws', () async {
      when(() => mockRemoteDataSource.getToken()).thenThrow(Exception());

      final result = await repository.getToken();

      expect(result, isNull);
      verify(() => mockRemoteDataSource.getToken()).called(1);
      verify(
        () => mockLogger.e(
          'Error getting FCM token',
          error: any(named: 'error'),
        ),
      ).called(1);
      verifyNever(
        () => mockLogger.d(
          any(),
          error: any(named: 'error'),
        ),
      );
    });

    test(
      'logs debug and returns null for expected GMS-missing FCM errors',
      () async {
        when(() => mockRemoteDataSource.getToken()).thenThrow(
          Exception(
            '[firebase_messaging/unknown] java.io.IOException: '
            'MISSING_INSTANCEID_SERVICE',
          ),
        );

        final result = await repository.getToken();

        expect(result, isNull);
        verify(
          () => mockLogger.d(
            'FCM token unavailable on this device',
            error: any(named: 'error'),
          ),
        ).called(1);
        verifyNever(
          () => mockLogger.e(
            any(),
            error: any(named: 'error'),
          ),
        );
      },
    );
  });

  group('isExpectedFcmUnavailableError', () {
    test('matches known no-GMS patterns', () {
      expect(
        NotificationsRepositoryImpl.isExpectedFcmUnavailableError(
          Exception('MISSING_INSTANCEID_SERVICE'),
        ),
        isTrue,
      );
      expect(
        NotificationsRepositoryImpl.isExpectedFcmUnavailableError(
          Exception('SERVICE_NOT_AVAILABLE'),
        ),
        isTrue,
      );
      expect(
        NotificationsRepositoryImpl.isExpectedFcmUnavailableError(
          Exception('Google Play services not available'),
        ),
        isTrue,
      );
    });

    test('does not match unexpected failures', () {
      expect(
        NotificationsRepositoryImpl.isExpectedFcmUnavailableError(
          Exception('network timeout'),
        ),
        isFalse,
      );
    });
  });

  group('initializeListeners', () {
    test(
      'registers a payload handler that accepts actionType aliases',
      () async {
        bool Function(String? payload)? matcher;

        when(
          () => mockDispatcher.registerPayloadHandler(
            serviceId: any(named: 'serviceId'),
            matcher: any(named: 'matcher'),
            handler: any(named: 'handler'),
          ),
        ).thenAnswer((invocation) {
          matcher =
              invocation.namedArguments[#matcher]
                  as bool Function(String? payload);
        });
        when(
          () => mockRemoteDataSource.onMessage,
        ).thenAnswer((_) => const Stream.empty());
        when(
          () => mockRemoteDataSource.onMessageOpenedApp,
        ).thenAnswer((_) => const Stream.empty());
        when(
          () => mockRemoteDataSource.getInitialMessage(),
        ).thenAnswer((_) async => null);

        await repository.initializeListeners();

        expect(
          matcher?.call(
            jsonEncode({'actionType': 'reciter', 'actionData': '7'}),
          ),
          isTrue,
        );
        expect(matcher?.call(jsonEncode({'type': 'settings'})), isTrue);
        expect(
          matcher?.call(
            jsonEncode({
              'type': 'prayer',
              'prayer': 'fajr',
              'scheduled_time_ms': 1700000000000,
              'notification_id': 20000000,
              'adhan_enabled': true,
            }),
          ),
          isFalse,
        );
        expect(
          matcher?.call(
            jsonEncode({
              'actionType': 'prayer',
              'actionData': 'fajr',
              'prayer_key': 'fajr',
              'scheduled_ms': 1700000000000,
            }),
          ),
          isFalse,
        );
        expect(
          matcher?.call(jsonEncode({'type': 'prayer', 'data': 'fajr'})),
          isTrue,
        );
        expect(matcher?.call(jsonEncode({'type': 'prayer'})), isTrue);
        expect(
          matcher?.call(
            jsonEncode({
              'type': 'prayer',
              'prayer': 'fajr',
              'prayer_name': 'fajr',
              'prayer_key': 'fajr',
              'scheduled_time_ms': 1700000000000,
              'scheduled_ms': 1700000000000,
              'notification_id': 20000000,
              'adhan_enabled': true,
              'is_adhan_playing': true,
            }),
          ),
          isFalse,
        );
        expect(
          matcher?.call(jsonEncode({'type': 'reciter', 'data': '7'})),
          isTrue,
        );
        expect(
          matcher?.call(jsonEncode({'type': 'athkar', 'data': 'morning'})),
          isTrue,
        );
        expect(
          matcher?.call(jsonEncode({'reciterName': 'Test Reciter'})),
          isFalse,
        );
        expect(matcher?.call(jsonEncode({'foo': 'bar'})), isFalse);
        verify(
          () => mockDispatcher.registerPayloadHandler(
            serviceId: 'fcm_service',
            matcher: any(named: 'matcher'),
            handler: any(named: 'handler'),
          ),
        ).called(1);
      },
    );

    test(
      'teacher_application_reviewed foreground message notifies capability refresh',
      () async {
        final messageController = StreamController<RemoteMessage>.broadcast();
        when(
          () => mockRemoteDataSource.onMessage,
        ).thenAnswer((_) => messageController.stream);
        when(
          () => mockRemoteDataSource.onMessageOpenedApp,
        ).thenAnswer((_) => const Stream.empty());
        when(
          () => mockFcmHandlerService.showForegroundNotification(any()),
        ).thenAnswer((_) async {});

        await repository.initializeListeners();

        messageController.add(
          RemoteMessage(
            data: const {
              'actionType': 'teacher_application_reviewed',
              'status': 'approved',
              'applicationId': 'app_1',
            },
          ),
        );
        await Future<void>.delayed(Duration.zero);

        verify(
          () => mockTeacherCapabilityRefreshNotifier.notifyApplicationReviewed(
            'approved',
          ),
        ).called(1);
        verify(
          () => mockFcmHandlerService.showForegroundNotification(any()),
        ).called(1);

        await messageController.close();
      },
    );

    test(
      'session_revoked foreground message notifies session revoked',
      () async {
        final messageController = StreamController<RemoteMessage>.broadcast();
        when(
          () => mockRemoteDataSource.onMessage,
        ).thenAnswer((_) => messageController.stream);
        when(
          () => mockRemoteDataSource.onMessageOpenedApp,
        ).thenAnswer((_) => const Stream.empty());
        when(
          () => mockFcmHandlerService.showForegroundNotification(any()),
        ).thenAnswer((_) async {});

        await repository.initializeListeners();

        messageController.add(
          RemoteMessage(
            data: const {
              'actionType': 'session_revoked',
            },
          ),
        );
        await Future<void>.delayed(Duration.zero);

        verify(
          () => mockSessionRevokedNotifier.notifySessionRevoked(),
        ).called(1);
        await messageController.close();
      },
    );

    test(
      'session_taken_over foreground message notifies session takeover',
      () async {
        final messageController = StreamController<RemoteMessage>.broadcast();
        when(
          () => mockRemoteDataSource.onMessage,
        ).thenAnswer((_) => messageController.stream);
        when(
          () => mockRemoteDataSource.onMessageOpenedApp,
        ).thenAnswer((_) => const Stream.empty());
        when(
          () => mockFcmHandlerService.showForegroundNotification(any()),
        ).thenAnswer((_) async {});

        await repository.initializeListeners();

        messageController.add(
          RemoteMessage(
            data: const {
              'actionType': 'session_taken_over',
              'sessionId': 'session_42',
            },
          ),
        );
        await Future<void>.delayed(Duration.zero);

        verify(
          () => mockSessionTakenOverNotifier.notifySessionTakenOver(
            'session_42',
          ),
        ).called(1);
        await messageController.close();
      },
    );

    test(
      'device_revoked foreground message notifies device revocation',
      () async {
        final messageController = StreamController<RemoteMessage>.broadcast();
        when(
          () => mockRemoteDataSource.onMessage,
        ).thenAnswer((_) => messageController.stream);
        when(
          () => mockRemoteDataSource.onMessageOpenedApp,
        ).thenAnswer((_) => const Stream.empty());
        when(
          () => mockFcmHandlerService.showForegroundNotification(any()),
        ).thenAnswer((_) async {});

        await repository.initializeListeners();

        messageController.add(
          RemoteMessage(
            data: const {'actionType': 'device_revoked'},
          ),
        );
        await Future<void>.delayed(Duration.zero);

        verify(
          () => mockDeviceRevokedNotifier.notifyDeviceRevoked(),
        ).called(1);
        await messageController.close();
      },
    );
  });
}
