import '../../domain/entities/session_registration.dart';

abstract class ActiveDeviceRemoteDataSource {
  Future<SessionRegistration> registerActiveDevice({
    required String deviceId,
    required String fcmToken,
    required String platform,
    String? appVersion,
    bool signOut = false,
  });
}
