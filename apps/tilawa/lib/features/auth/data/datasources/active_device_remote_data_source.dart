import '../../domain/entities/device_info_snapshot.dart';
import '../../domain/entities/session_registration.dart';

abstract class ActiveDeviceRemoteDataSource {
  Future<SessionRegistration> registerActiveDevice({
    required String deviceId,
    required DeviceRegistrationMode registrationMode,
    required String platform,
    String? fcmToken,
    String? appVersion,
    DeviceInfoSnapshot? deviceInfo,
    bool signOut = false,
  });
}
