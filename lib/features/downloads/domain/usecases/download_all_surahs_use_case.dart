import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../../../surah/domain/entities/surah_entity.dart';
import '../repositories/downloads_repository.dart';

@Singleton()
class DownloadAllSurahsUseCase {
  const DownloadAllSurahsUseCase(this._repository);

  final DownloadsRepository _repository;

  ResultFuture<void> call({
    required List<SurahEntity> surahs,
    required String reciterName,
    required int reciterId,
  }) async {
    try {
      for (final surah in surahs) {
        // Skip if already downloaded (repository check or local check)
        // Ideally we should check with repository to be sure, but to avoid N async calls here
        // we can rely on startDownload to handle duplicates efficiently or checking current state.

        // However, checking isSurahDownloaded for each might be slow if list is long.
        // But since startDownload is async, we can fire and forget or await.
        // Let's await to ensure order and prevent flooding if possible, though QueueManager handles flooding.

        // We'll rely on the repository's startDownload which should handle logic.
        // But optimization: check `surah.isDownloaded` from entity first?
        // Entity status updates might be delayed.

        // Let's just call startDownload. The DownloadQueueManager handles concurrency.
        await _repository.startDownload(
          surah.id,
          surah.name,
          reciterName,
          reciterId,
        );
      }
      return const Right(null);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}
