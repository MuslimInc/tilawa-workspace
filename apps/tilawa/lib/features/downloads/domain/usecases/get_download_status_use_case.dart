import 'package:injectable/injectable.dart';

import '../entities/download_item.dart';
import '../services/download_service_interface.dart';

@Singleton()
class GetDownloadStatusUseCase {
  const GetDownloadStatusUseCase(this._downloadService);

  final DownloadServiceInterface _downloadService;

  Future<DownloadStatus?> call(String taskId) {
    return _downloadService.getStatus(taskId);
  }
}
