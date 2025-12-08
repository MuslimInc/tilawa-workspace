import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import '../../domain/repositories/downloads_repository.dart';

final logger = Logger();

@singleton
class DownloadsInitializationService {
  DownloadsInitializationService(this._downloadsRepository);

  final DownloadsRepository _downloadsRepository;

  /// Initialize downloads feature
  /// This checks for any pending or stuck downloads and resumes them
  Future<void> initialize() async {
    try {
      await _downloadsRepository.resumePendingDownloads();
      logger.d('DownloadsInitializationService: Initialization completed');
    } catch (e) {
      logger.e('DownloadsInitializationService: Initialization failed: $e');
    }
  }
}
