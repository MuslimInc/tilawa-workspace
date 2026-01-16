import 'package:injectable/injectable.dart';

import '../../data/models/download_progress.dart';
import '../../data/services/download_service_interface.dart';

@Singleton()
class ObserveGlobalDownloadProgressUseCase {
  ObserveGlobalDownloadProgressUseCase(this._downloadService);
  final DownloadServiceInterface _downloadService;

  Stream<DownloadProgress> call() {
    return _downloadService.globalProgressStream;
  }
}
