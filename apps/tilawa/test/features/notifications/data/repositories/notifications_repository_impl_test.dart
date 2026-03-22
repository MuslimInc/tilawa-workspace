import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
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

void main() {
  late NotificationsRepositoryImpl repository;
  late MockNotificationsRemoteDataSource mockRemoteDataSource;
  late MockINotificationDispatcher mockDispatcher;
  late MockFCMNotificationHandlerService mockFcmHandlerService;

  setUp(() {
    mockRemoteDataSource = MockNotificationsRemoteDataSource();
    mockDispatcher = MockINotificationDispatcher();
    mockFcmHandlerService = MockFCMNotificationHandlerService();
    repository = NotificationsRepositoryImpl(
      mockRemoteDataSource,
      mockDispatcher,
      mockFcmHandlerService,
    );
  });

  group('requestPermission', () {
    test('should call requestPermission on remote data source', () async {
      // Arrange
      final settings = MockNotificationSettings();
      when(
        () => settings.authorizationStatus,
      ).thenReturn(AuthorizationStatus.authorized);
      when(
        () => mockRemoteDataSource.requestPermission(),
      ).thenAnswer((_) async => settings);

      // Act
      await repository.requestPermission();

      // Assert
      verify(() => mockRemoteDataSource.requestPermission()).called(1);
    });
  });

  group('getToken', () {
    test('should return token from remote data source', () async {
      // Arrange
      const tToken = 'test_token';
      when(() => mockRemoteDataSource.getToken()).thenAnswer((_) async => tToken);

      // Act
      final String? result = await repository.getToken();

      // Assert
      expect(result, tToken);
      verify(() => mockRemoteDataSource.getToken()).called(1);
    });

    test('should return null when exception occurs', () async {
      // Arrange
      when(() => mockRemoteDataSource.getToken()).thenThrow(Exception());

      // Act
      final String? result = await repository.getToken();

      // Assert
      expect(result, null);
      verify(() => mockRemoteDataSource.getToken()).called(1);
    });
    group('initializeListeners', () {
      test('should register payload handler and listen to streams', () async {
        // Arrange
        when(() => mockDispatcher.registerPayloadHandler(
              serviceId: any(named: 'serviceId'),
              matcher: any(named: 'matcher'),
              handler: any(named: 'handler'),
            )).thenReturn(null);
      when(() => mockRemoteDataSource.onMessage).thenAnswer((_) => const Stream.empty());
      when(() => mockRemoteDataSource.onMessageOpenedApp).thenAnswer((_) => const Stream.empty());

      // Act
      await repository.initializeListeners();

      // Assert
      verify(() => mockDispatcher.registerPayloadHandler(
        serviceId: 'fcm_service',
        matcher: any(named: 'matcher'),
        handler: any(named: 'handler'),
      )).called(1);
    });
  });
  });
}
