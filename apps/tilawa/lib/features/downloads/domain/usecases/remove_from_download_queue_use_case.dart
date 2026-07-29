import '../services/download_queue_service_interface.dart';

class RemoveFromDownloadQueueUseCase {
  const RemoveFromDownloadQueueUseCase(this._queueService);

  final IDownloadQueueService _queueService;

  void call(String taskId) {
    _queueService.removeFromQueue(taskId);
  }
}
