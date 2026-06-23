import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';

abstract class NotificationsRemoteDataSource {
  Future<NotificationSettings> requestPermission();
  Future<String?> getToken();
  Stream<RemoteMessage> get onMessage;
  Stream<RemoteMessage> get onMessageOpenedApp;
  Future<RemoteMessage?> getInitialMessage();
}

@LazySingleton(as: NotificationsRemoteDataSource)
class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  NotificationsRemoteDataSourceImpl(this._firebaseMessaging);
  final FirebaseMessaging _firebaseMessaging;

  @override
  Future<NotificationSettings> requestPermission() {
    return _firebaseMessaging.requestPermission();
  }

  @override
  Future<String?> getToken() {
    return _firebaseMessaging.getToken();
  }

  @override
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  @override
  Future<RemoteMessage?> getInitialMessage() =>
      _firebaseMessaging.getInitialMessage();
}
