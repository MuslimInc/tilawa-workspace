import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tilawa_core/entities/app_info.dart';
import 'package:tilawa_core/services/interfaces/app_info_service.dart';

@LazySingleton(as: AppInfoService)
class AppInfoServiceImpl implements AppInfoService {
  @override
  Future<AppInfo> getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return AppInfo(
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      appName: packageInfo.appName,
      packageName: packageInfo.packageName,
    );
  }
}
