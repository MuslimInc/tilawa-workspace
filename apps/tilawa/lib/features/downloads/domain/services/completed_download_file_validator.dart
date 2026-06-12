import 'dart:math' as math;

import 'package:injectable/injectable.dart';

import '../entities/download_item.dart';
import '../repositories/downloads_repository.dart';

/// Validates on-disk files for completed downloads in bounded parallel batches.
@injectable
class CompletedDownloadFileValidator {
  const CompletedDownloadFileValidator(this._repository);

  /// Keeps large libraries responsive by yielding between batches.
  static const int defaultBatchSize = 32;

  final DownloadsRepository _repository;

  /// Returns [downloads] whose files still exist, preserving input order.
  Future<List<DownloadItem>> validateExistingFiles(
    List<DownloadItem> downloads, {
    int batchSize = defaultBatchSize,
  }) async {
    if (downloads.isEmpty) {
      return const [];
    }

    final List<DownloadItem> valid = <DownloadItem>[];
    for (var offset = 0; offset < downloads.length; offset += batchSize) {
      final int end = math.min(offset + batchSize, downloads.length);
      final List<bool> validations = await Future.wait(
        List<Future<bool>>.generate(
          end - offset,
          (int index) =>
              _repository.validateDownloadedFile(downloads[offset + index]),
        ),
      );

      for (var index = 0; index < validations.length; index++) {
        if (validations[index]) {
          valid.add(downloads[offset + index]);
        }
      }

      if (end < downloads.length) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    return valid;
  }
}
