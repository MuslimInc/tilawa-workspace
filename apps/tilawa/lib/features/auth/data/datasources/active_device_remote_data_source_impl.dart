import 'package:cloud_functions/cloud_functions.dart';
import 'package:injectable/injectable.dart';

import '../../device_registry_feature_flags.dart';
import '../../domain/entities/device_info_snapshot.dart';
import '../../domain/entities/session_registration.dart';
import 'active_device_remote_data_source.dart';

@LazySingleton(as: ActiveDeviceRemoteDataSource)
class ActiveDeviceRemoteDataSourceImpl implements ActiveDeviceRemoteDataSource {
  ActiveDeviceRemoteDataSourceImpl(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<SessionRegistration> registerActiveDevice({
    required String deviceId,
    required DeviceRegistrationMode registrationMode,
    required String platform,
    String? fcmToken,
    String? appVersion,
    DeviceInfoSnapshot? deviceInfo,
    bool signOut = false,
  }) async {
    final callable = _functions.httpsCallable('registerActiveDevice');
    final deviceInfoJson = _deviceInfoJson(deviceInfo);
    // ADR-008 Phase 0: opt into the additive device-registry write when the
    // launch flag is on. Never sent on sign-out (the server ignores it anyway).
    final writeDeviceRegistry = !signOut && isDeviceRegistryWriteEnabled();
    final response = await callable.call<Map<String, dynamic>>({
      'deviceId': deviceId,
      'fcmToken': ?fcmToken,
      'platform': platform,
      'registrationMode': registrationMode.wireName,
      'appVersion': ?appVersion,
      'deviceInfo': ?deviceInfoJson,
      if (signOut) 'signOut': true,
      if (writeDeviceRegistry) 'writeDeviceRegistry': true,
    });

    final data = response.data;
    return SessionRegistration(
      status: SessionRegistrationStatus.fromWireName(data['status'] as String?),
      sessionEpoch:
          (data['sessionEpoch'] as num?)?.toInt() ??
          (data['epoch'] as num?)?.toInt(),
      activeDeviceId: data['activeDeviceId'] as String? ?? deviceId,
      deviceCapExceeded: data['deviceCapExceeded'] as bool?,
      registeredDeviceCount: (data['registeredDeviceCount'] as num?)?.toInt(),
    );
  }

  Map<String, String>? _deviceInfoJson(DeviceInfoSnapshot? deviceInfo) {
    final json = deviceInfo?.toJson();
    if (json == null || json.isEmpty) {
      return null;
    }
    return json;
  }
}
