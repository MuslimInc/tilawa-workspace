import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_data_source.dart';

@LazySingleton(as: NotificationsRepository)
class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._remoteDataSource);
  final NotificationsRemoteDataSource _remoteDataSource;
  final Logger _logger = Logger();

  @override
  Future<void> requestPermission() async {
    final NotificationSettings settings = await _remoteDataSource
        .requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _logger.d('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      _logger.d('User granted provisional permission');
    } else {
      _logger.d('User declined or has not accepted permission');
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      final String? token = await _remoteDataSource.getToken();
      _logger.d('FCM Token: $token');
      return token;
    } catch (e) {
      _logger.e('Error getting FCM token', error: e);
      return null;
    }
  }

  @override
  Future<void> initializeListeners() async {
    // Handle Foreground Messages
    _remoteDataSource.onMessage.listen((RemoteMessage message) {
      _logger.d('Got a message whilst in the foreground!');
      _logger.d(r'Message data: ${message.data}');

      if (message.notification != null) {
        _logger.d(
          r'Message also contained a notification: ${message.notification}',
        );
        // TODO: Show local notification (Use a UseCase or Helper for UI logic if needed)
      }
    });

    // Handle Background/Terminated Messages (when opened)
    _remoteDataSource.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.d('A new onMessageOpenedApp event was published!');
      // TODO: Handle navigation (Use a RouterService or similar)
    });
  }
}
