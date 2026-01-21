import 'package:injectable/injectable.dart';

import '../../data/services/download_service_interface.dart';
import '../../domain/entities/download_item.dart';

@Singleton()
class GetDownloadStatusUseCase {
  const GetDownloadStatusUseCase(this._downloadService);

  final DownloadServiceInterface _downloadService;

  Future<DownloadStatus?> call(String taskId) {
    return _downloadService.getStatus(taskId);
  }
}
