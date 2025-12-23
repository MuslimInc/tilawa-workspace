import 'package:injectable/injectable.dart';

import '../../data/services/download_service.dart';

@Singleton()
class ObserveGlobalDownloadProgressUseCase {
  ObserveGlobalDownloadProgressUseCase(this._downloadService);
  final DownloadService _downloadService;

  Stream<DownloadProgress> call() {
    return _downloadService.globalProgressStream;
  }
}
