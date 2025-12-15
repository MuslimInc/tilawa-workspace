import 'package:audio_service/audio_service.dart';
import 'package:injectable/injectable.dart';

import '../../../downloads/domain/entities/download_item.dart';
import '../../../downloads/domain/repositories/downloads_repository.dart';
import '../entities/surah_entity.dart';
import '../mappers/surah_mapper.dart';
import '../repositories/surah_repository.dart';

@Singleton()
class ConvertMediaItemsToSurahsUseCase {
  const ConvertMediaItemsToSurahsUseCase(
    this._surahRepository,
    this._downloadsRepository,
  );

  final SurahRepository _surahRepository;
  final DownloadsRepository _downloadsRepository;

  Future<List<SurahEntity>> call(List<MediaItem> mediaItems) async {
    final surahList = <SurahEntity>[];

    // Batch fetch download statuses for all items
    List<DownloadItem> downloads = [];
    if (mediaItems.isNotEmpty) {
      final String reciterName = mediaItems.first.artist ?? '';
      if (reciterName.isNotEmpty) {
        downloads = await _downloadsRepository.getDownloadsForReciter(
          reciterName,
        );
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

    for (final mediaItem in mediaItems) {
      // Convert MediaItem to Surah
      SurahEntity surah = SurahMapper.fromMediaItem(mediaItem);

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
