import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/notifications/data/datasources/notifications_remote_data_source.dart';

import '../../../../helpers/firebase_messaging_helper.mocks.dart';

void main() {
  late NotificationsRemoteDataSourceImpl dataSource;
  late MockFirebaseMessaging mockFirebaseMessaging;

  setUp(() {
    mockFirebaseMessaging = MockFirebaseMessaging();
    dataSource = NotificationsRemoteDataSourceImpl(mockFirebaseMessaging);
  });

  group('requestPermission', () {
    test('should call requestPermission on FirebaseMessaging', () async {
      // Arrange
      final settings = MockNotificationSettings();
      when(
        settings.authorizationStatus,
      ).thenReturn(AuthorizationStatus.authorized);

      when(
        mockFirebaseMessaging.requestPermission(
          alert: anyNamed('alert'),
          badge: anyNamed('badge'),
          sound: anyNamed('sound'),
          announcement: anyNamed('announcement'),
          carPlay: anyNamed('carPlay'),
          criticalAlert: anyNamed('criticalAlert'),
          provisional: anyNamed('provisional'),
        ),
      ).thenAnswer((_) async => settings);

      // Act
      final NotificationSettings result = await dataSource.requestPermission();

      // Assert
      expect(result, settings);
      verify(mockFirebaseMessaging.requestPermission());
    });
  });

  group('getToken', () {
    test('should return token from FirebaseMessaging', () async {
      // Arrange
      const tToken = 'test_token';
      when(mockFirebaseMessaging.getToken()).thenAnswer((_) async => tToken);

      // Act
      final String? result = await dataSource.getToken();

      // Assert
      expect(result, tToken);
      verify(mockFirebaseMessaging.getToken());
    });
  });
}
