import '../../entities/app_info.dart';

abstract interface class AppInfoService {
  Future<AppInfo> getAppInfo();
}
