import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:tilawa/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:tilawa/features/notifications/presentation/services/fcm_notification_handler_service.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

class MockNotificationsRemoteDataSource extends Mock
    implements NotificationsRemoteDataSource {}

class MockNotificationSettings extends Mock implements NotificationSettings {}

class MockINotificationDispatcher extends Mock
    implements INotificationDispatcher {}

class MockFCMNotificationHandlerService extends Mock
    implements FCMNotificationHandlerService {}

class MockLogger extends Mock implements Logger {}

void main() {
  late NotificationsRepositoryImpl repository;
  late MockNotificationsRemoteDataSource mockRemoteDataSource;
  late MockINotificationDispatcher mockDispatcher;
  late MockFCMNotificationHandlerService mockFcmHandlerService;
  late MockLogger mockLogger;

  setUp(() {
    mockRemoteDataSource = MockNotificationsRemoteDataSource();
    mockDispatcher = MockINotificationDispatcher();
    mockFcmHandlerService = MockFCMNotificationHandlerService();
    mockLogger = MockLogger();

    repository = NotificationsRepositoryImpl(
      mockRemoteDataSource,
      mockDispatcher,
      mockFcmHandlerService,
      mockLogger,
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
  });
}
