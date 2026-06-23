import 'package:cloud_functions/cloud_functions.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/session_registration.dart';
import 'active_device_remote_data_source.dart';

@LazySingleton(as: ActiveDeviceRemoteDataSource)
class ActiveDeviceRemoteDataSourceImpl implements ActiveDeviceRemoteDataSource {
  ActiveDeviceRemoteDataSourceImpl(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<SessionRegistration> registerActiveDevice({
    required String deviceId,
    required String fcmToken,
    required String platform,
    String? appVersion,
    bool signOut = false,
  }) async {
    final callable = _functions.httpsCallable('registerActiveDevice');
    final response = await callable.call<Map<String, dynamic>>({
      'deviceId': deviceId,
      'fcmToken': fcmToken,
      'platform': platform,
      'appVersion': ?appVersion,
      if (signOut) 'signOut': true,
    });

    final data = response.data;
    return SessionRegistration(
      epoch: (data['epoch'] as num?)?.toInt() ?? 0,
      activeDeviceId: data['activeDeviceId'] as String? ?? deviceId,
    );
  }
}
