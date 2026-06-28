import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/auth/data/services/platform_device_info_service.dart';
import 'package:tilawa_core/entities/app_info.dart';
import 'package:tilawa_core/services/interfaces/app_info_service.dart';

class MockDeviceInfoPlugin extends Mock implements DeviceInfoPlugin {}

class MockAndroidDeviceInfo extends Mock implements AndroidDeviceInfo {}

class MockAndroidBuildVersion extends Mock implements AndroidBuildVersion {}

class FakeAppInfoService implements AppInfoService {
  @override
  Future<AppInfo> getAppInfo() async {
    return const AppInfo(
      version: '2.0.16',
      buildNumber: '63',
      appName: 'MeMuslim',
      packageName: 'com.tilawa',
    );
  }
}

void main() {
  test('getDeviceInfo returns safe Android support fields only', () async {
    final deviceInfoPlugin = MockDeviceInfoPlugin();
    final androidInfo = MockAndroidDeviceInfo();
    final androidVersion = MockAndroidBuildVersion();
    when(() => deviceInfoPlugin.androidInfo).thenAnswer((_) async {
      return androidInfo;
    });
    when(() => androidInfo.manufacturer).thenReturn('OPPO');
    when(() => androidInfo.model).thenReturn('A98 5G');
    when(() => androidInfo.version).thenReturn(androidVersion);
    when(() => androidVersion.release).thenReturn('15');

    final service = PlatformDeviceInfoService.forPlatform(
      deviceInfoPlugin: deviceInfoPlugin,
      appInfoService: FakeAppInfoService(),
      isAndroid: true,
      isIOS: false,
    );

    final snapshot = await service.getDeviceInfo();
    final json = snapshot.toJson();

    expect(json, {
      'manufacturer': 'OPPO',
      'model': 'A98 5G',
      'os': 'Android',
      'osVersion': '15',
      'appBuildNumber': '63',
      'appVersion': '2.0.16',
    });
    expect(json.containsKey('imei'), isFalse);
    expect(json.containsKey('serialNumber'), isFalse);
    expect(json.containsKey('macAddress'), isFalse);
    expect(json.containsKey('advertisingId'), isFalse);
  });
}
