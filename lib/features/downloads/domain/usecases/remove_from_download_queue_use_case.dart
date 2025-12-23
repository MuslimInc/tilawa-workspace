import 'package:injectable/injectable.dart';

import '../../data/services/download_queue_manager.dart';

@Singleton()
class RemoveFromDownloadQueueUseCase {
  const RemoveFromDownloadQueueUseCase(this._queueManager);

  final DownloadQueueManager _queueManager;

  void call(String taskId) {
    _queueManager.removeFromQueue(taskId);
  }
}
