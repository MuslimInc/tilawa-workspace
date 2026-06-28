import '../entities/device_info_snapshot.dart';

abstract class DeviceInfoService {
  Future<DeviceInfoSnapshot> getDeviceInfo();
}
