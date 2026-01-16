import 'dart:io';

import 'package:injectable/injectable.dart';

import '../../../../../main.dart'; // For logger
import '../../../utils/download_path_utils.dart';

@lazySingleton
class DownloadFileHelper {
  /// Extract directory name from file path
  String getDirectoryName(String filePath) {
    return DownloadPathUtils.getDirectoryName(filePath);
  }

  /// Extract file name from file path
  String getFileName(String filePath) {
    return DownloadPathUtils.getFileName(filePath);
  }

  /// Ensure the directory exists, create if necessary.
  bool ensureDirectoryExists(String savedDir) {
    final dir = Directory(savedDir);
    if (!dir.existsSync()) {
      try {
        dir.createSync(recursive: true);
        return true;
      } catch (e) {
        logger.e(
          '[DownloadService] Failed to create download directory: $savedDir error: $e',
        );
        return false;
      }
    }
    return true;
  }

  /// Check if a file exists.
  bool isFileExists(String filePath) {
    final file = File(filePath);
    try {
      // Use synchronous check to satisfy `dartavoid_slow_async_io` lint
      return file.existsSync();
    } catch (e) {
      logger.w(
        '[DownloadService] Error checking file existence for $filePath: $e',
      );
      return false;
    }
  }
}
