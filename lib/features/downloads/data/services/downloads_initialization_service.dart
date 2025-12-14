import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import '../../domain/repositories/downloads_repository.dart';
import 'download_notification_service.dart';

final logger = Logger();

@singleton
class DownloadsInitializationService {
  DownloadsInitializationService(
    this._downloadsRepository,
    this._downloadNotificationService,
  );

  final DownloadsRepository _downloadsRepository;
  final DownloadNotificationService _downloadNotificationService;

  /// Initialize downloads feature
  /// This checks for any pending or stuck downloads and resumes them
  Future<void> initialize() async {
    try {
      await _downloadNotificationService.initialize();
      await _downloadsRepository.resumePendingDownloads();
      logger.d('DownloadsInitializationService: Initialization completed');
    } catch (e) {
      logger.e('DownloadsInitializationService: Initialization failed: $e');
    }
  }
}
