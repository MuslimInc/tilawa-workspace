import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/entities/audio.dart';
import '../../../../core/entities/reciter_entity.dart';
import '../../../../core/errors/failures.dart';
import '../../../downloads/domain/entities/download_item.dart';
import '../../../downloads/domain/repositories/downloads_repository.dart';
import '../../../reciters/domain/repositories/reciters_repository.dart';
import '../entities/surah_entity.dart';
import '../mappers/surah_mapper.dart';
import '../repositories/surah_repository.dart';

@injectable
class ConvertAudioEntitiesToSurahsUseCase {
  const ConvertAudioEntitiesToSurahsUseCase(
    this._surahRepository,
    this._downloadsRepository,
    this._recitersRepository,
  );

  final SurahRepository _surahRepository;
  final DownloadsRepository _downloadsRepository;
  final RecitersRepository _recitersRepository;

  Future<List<SurahEntity>> call(List<AudioEntity> audioEntities) async {
    final surahList = <SurahEntity>[];

    // Batch fetch download statuses for all items
    final List<DownloadItem> downloads = [];
    if (audioEntities.isNotEmpty) {
      final String reciterName = audioEntities.first.artist ?? '';
      if (reciterName.isNotEmpty) {
        // 1. Get all downloads
        final List<DownloadItem> allDownloads = await _downloadsRepository
            .getAllDownloads();

        // 2. Resolve Reciter ID
        final Either<Failure, List<ReciterEntity>> recitersResult =
            await _recitersRepository.getReciters();

        final int? reciterId = recitersResult.fold((l) => null, (reciters) {
          try {
            return reciters.firstWhere((r) => r.name == reciterName).id;
          } catch (_) {
            return null;
          }
        });

        // 3. Filter
        for (final download in allDownloads) {
          var isMatch = false;
          if (reciterId != null && download.reciterId == reciterId) {
            isMatch = true;
          } else if (download.reciterName == reciterName) {
            isMatch = true;
          }
          if (isMatch) {
            downloads.add(download);
          }
        }
      }
    }

    // Create lookup maps for O(1) access
    final Set<String> downloadedUrls = {};
    final Set<String> downloadingUrls = {};
    final Map<String, double> progressMap = {};
    final Map<String, String> downloadIdMap = {};

    for (final download in downloads) {
      if (download.status == DownloadStatus.completed) {
        downloadedUrls.add(download.url);
      } else if (download.status == DownloadStatus.downloading ||
          download.status == DownloadStatus.pending) {
        downloadingUrls.add(download.url);
        progressMap[download.url] = download.progress;
      }
      downloadIdMap[download.url] = download.id;
    }

    for (final audio in audioEntities) {
      // Convert AudioEntity to Surah
      SurahEntity surah = SurahMapper.fromAudioEntity(audio);

      // Check status using in-memory maps
      // Note: surah.id is the URL
      final bool isDownloaded = downloadedUrls.contains(surah.id);
      final bool isDownloading = downloadingUrls.contains(surah.id);
      final double progress = progressMap[surah.id] ?? 0.0;
      final String? downloadId = downloadIdMap[surah.id];

      // Update surah with download status
      surah = surah.copyWith(
        isDownloaded: isDownloaded,
        isDownloading: isDownloading,
        downloadProgress: progress,
        downloadId: downloadId,
      );

      // Add to surah repository cache
      await _surahRepository.updateSurah(surah);

      surahList.add(surah);
    }

    return surahList;
  }
}
