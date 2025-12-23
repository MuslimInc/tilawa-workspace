import 'package:injectable/injectable.dart';

import '../../data/services/download_service.dart';
import '../../domain/entities/download_item.dart';

@Singleton()
class GetDownloadStatusUseCase {
  const GetDownloadStatusUseCase(this._downloadService);

  final DownloadService _downloadService;

  Future<DownloadStatus?> call(String taskId) {
    return _downloadService.getStatus(taskId);
  }
}
