import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';

abstract class DeviceTokenService {
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;
}

@LazySingleton(as: DeviceTokenService)
class DeviceTokenServiceImpl implements DeviceTokenService {
  DeviceTokenServiceImpl(this._firebaseMessaging);

  final FirebaseMessaging _firebaseMessaging;

  @override
  Future<String?> getToken() => _firebaseMessaging.getToken();

  @override
  Stream<String> get onTokenRefresh => _firebaseMessaging.onTokenRefresh;
}
