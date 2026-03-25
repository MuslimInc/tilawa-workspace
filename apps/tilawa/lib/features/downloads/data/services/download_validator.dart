import 'dart:io';

import 'package:injectable/injectable.dart';

import 'package:tilawa/core/logging/app_logger.dart';
import '../datasources/downloads_local_datasource.dart';

@LazySingleton()
class DownloadValidator {
  DownloadValidator(this._localDataSource);

  final DownloadsLocalDataSource _localDataSource;

  /// Verifies if a file exists on disk, with a retry mechanism to account for
  /// asynchronous I/O completion after a download task finish.
  Future<bool> verifyFileExists(String filePath, {int maxRetries = 1}) async {
    for (var i = 0; i < maxRetries; i++) {
      if (_localDataSource.isFileExists(filePath)) {
        return true;
      }
      if (i < maxRetries - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    return false;
  }

  /// Verifies if the file size on disk matches the expected file size.
  /// Allows for a small tolerance (1%) to account for minor metadata differences.
  Future<bool> verifyFileSize(String filePath, int expectedSize) async {
    if (expectedSize <= 0) {
      return true;
    }

    try {
      final file = File(filePath);
      final int actualSize = await file.length();
      final int tolerance = (expectedSize * 0.01).round();
      final int sizeDiff = (actualSize - expectedSize).abs();

      if (sizeDiff > tolerance) {
        logger.w(
          '[DownloadValidator] File size mismatch: expected=$expectedSize actual=$actualSize diff=$sizeDiff',
        );
        return false;
      }
      return true;
    } catch (e) {
      logger.e('[DownloadValidator] Error verifying file size: $e');
      return false;
    }
  }

  /// Checks if a file exists and returns its actual size.
  Future<int?> getActualFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        return await file.length();
      }
    } catch (e) {
      logger.w('[DownloadValidator] Failed to get file size from disk: $e');
    }
    return null;
  }
}
