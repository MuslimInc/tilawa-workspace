import 'dart:io';

import '../../../../../../main.dart'; // For logger
import '../../../utils/download_path_utils.dart';

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
  Future<bool> ensureDirectoryExists(String savedDir) async {
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
}
