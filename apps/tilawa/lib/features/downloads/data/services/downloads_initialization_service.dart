import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import '../../domain/repositories/downloads_repository.dart';
import '../../domain/services/download_notification_service_interface.dart';
import 'batch_download_manager.dart';

final logger = Logger();

@singleton
class DownloadsInitializationService {
  DownloadsInitializationService(
    this._downloadsRepository,
    this._downloadNotificationService,
    this._batchDownloadManager,
  );

  final DownloadsRepository _downloadsRepository;
  final IDownloadNotificationService _downloadNotificationService;
  final BatchDownloadManager _batchDownloadManager;

  /// Initialize downloads feature
  /// This checks for any pending or stuck downloads and resumes them
  Future<void> initialize() async {
    try {
      await _downloadNotificationService.initialize();
      await _batchDownloadManager.initialize();
      await _downloadsRepository.initialize();
      await _downloadsRepository.resumePendingDownloads();
      logger.d('DownloadsInitializationService: Initialization completed');
    } catch (e) {
      logger.e('DownloadsInitializationService: Initialization failed: $e');
    }
  }
}
