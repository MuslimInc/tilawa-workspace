import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';

abstract class NotificationsRemoteDataSource {
  Future<NotificationSettings> requestPermission();
  Future<String?> getToken();
  Future<void> saveToken(String userId, String token);
  Stream<RemoteMessage> get onMessage;
  Stream<RemoteMessage> get onMessageOpenedApp;
}

@LazySingleton(as: NotificationsRemoteDataSource)
class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  NotificationsRemoteDataSourceImpl(this._firebaseMessaging, this._firestore);
  final FirebaseMessaging _firebaseMessaging;
  final FirebaseFirestore _firestore;

  @override
  Future<NotificationSettings> requestPermission() {
    return _firebaseMessaging.requestPermission();
  }

  @override
  Future<String?> getToken() {
    return _firebaseMessaging.getToken();
  }

  @override
  Future<void> saveToken(String userId, String token) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('fcm_tokens')
        .doc(token)
        .set({
          'token': token,
          'createdAt': FieldValue.serverTimestamp(),
          'platform': Platform.isAndroid ? 'android' : 'ios',
        });
  }

  @override
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;
}
