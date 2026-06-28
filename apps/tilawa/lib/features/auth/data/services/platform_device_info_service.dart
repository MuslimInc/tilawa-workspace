import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/entities/app_info.dart';
import 'package:tilawa_core/services/interfaces/app_info_service.dart';

import '../../domain/entities/device_info_snapshot.dart';
import '../../domain/services/device_info_service.dart';

@LazySingleton(as: DeviceInfoService)
class PlatformDeviceInfoService implements DeviceInfoService {
  PlatformDeviceInfoService(this._deviceInfoPlugin, this._appInfoService)
    : _isAndroid = !kIsWeb && Platform.isAndroid,
      _isIOS = !kIsWeb && Platform.isIOS;

  @visibleForTesting
  PlatformDeviceInfoService.forPlatform({
    required this._deviceInfoPlugin,
    required this._appInfoService,
    required this._isAndroid,
    required this._isIOS,
  });

  final DeviceInfoPlugin _deviceInfoPlugin;
  final AppInfoService _appInfoService;
  final bool _isAndroid;
  final bool _isIOS;

  @override
  Future<DeviceInfoSnapshot> getDeviceInfo() async {
    final AppInfo appInfo = await _appInfoService.getAppInfo();
    if (_isAndroid) {
      final AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
      return DeviceInfoSnapshot(
        manufacturer: _clean(androidInfo.manufacturer),
        model: _clean(androidInfo.model),
        os: 'Android',
        osVersion: _clean(androidInfo.version.release),
        appBuildNumber: appInfo.buildNumber,
        appVersion: appInfo.version,
      );
    }
    if (_isIOS) {
      final IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
      return DeviceInfoSnapshot(
        manufacturer: 'Apple',
        model: _clean(iosInfo.utsname.machine),
        os: _clean(iosInfo.systemName) ?? 'iOS',
        osVersion: _clean(iosInfo.systemVersion),
        appBuildNumber: appInfo.buildNumber,
        appVersion: appInfo.version,
      );
    }
    return DeviceInfoSnapshot(
      os: kIsWeb ? 'Web' : Platform.operatingSystem,
      appBuildNumber: appInfo.buildNumber,
      appVersion: appInfo.version,
    );
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
