import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:tilawa/features/notifications/data/repositories/notifications_repository_impl.dart';

import 'notifications_repository_impl_test.mocks.dart';

@GenerateMocks([NotificationsRemoteDataSource, NotificationSettings])
void main() {
  late NotificationsRepositoryImpl repository;
  late MockNotificationsRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockNotificationsRemoteDataSource();
    repository = NotificationsRepositoryImpl(mockRemoteDataSource);
  });

  group('requestPermission', () {
    test('should call requestPermission on remote data source', () async {
      // Arrange
      final settings = MockNotificationSettings();
      when(
        settings.authorizationStatus,
      ).thenReturn(AuthorizationStatus.authorized);
      when(
        mockRemoteDataSource.requestPermission(),
      ).thenAnswer((_) async => settings);

      // Act
      await repository.requestPermission();

      // Assert
      verify(mockRemoteDataSource.requestPermission());
    });
  });

  group('getToken', () {
    test('should return token from remote data source', () async {
      // Arrange
      const tToken = 'test_token';
      when(mockRemoteDataSource.getToken()).thenAnswer((_) async => tToken);

      // Act
      final String? result = await repository.getToken();

      // Assert
      expect(result, tToken);
      verify(mockRemoteDataSource.getToken());
    });

    test('should return null when exception occurs', () async {
      // Arrange
      when(mockRemoteDataSource.getToken()).thenThrow(Exception());

      // Act
      final String? result = await repository.getToken();

      // Assert
      expect(result, null);
      verify(mockRemoteDataSource.getToken());
    });
  });
}
