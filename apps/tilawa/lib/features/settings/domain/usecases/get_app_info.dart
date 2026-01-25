import 'package:injectable/injectable.dart';
import 'package:tilawa_core/entities/app_info.dart';
import 'package:tilawa_core/services/interfaces/app_info_service.dart';

@injectable
class GetAppInfo {
  GetAppInfo(this._appInfoService);

  final AppInfoService _appInfoService;

  Future<AppInfo> call() async {
    return _appInfoService.getAppInfo();
  }
}
