import '../entities/download_progress.dart';
import '../services/download_service_interface.dart';

class ObserveGlobalDownloadProgressUseCase {
  ObserveGlobalDownloadProgressUseCase(this._downloadService);
  final DownloadServiceInterface _downloadService;

  Stream<DownloadProgress> call() {
    return _downloadService.globalProgressStream;
  }
}
