import 'package:audio_service/audio_service.dart';
import 'package:muzakri/features/surah/domain/entities/surah_entity.dart';

class SurahMapper {
  /// Convert Surah to MediaItem
  static MediaItem toMediaItem(SurahEntity surah) {
    // Return the original MediaItem with updated extras
    return MediaItem(
      id: surah.mediaItem.id,
      title: surah.mediaItem.title,
      artist: surah.mediaItem.artist,
      album: surah.mediaItem.album,
      duration: surah.mediaItem.duration,
      artUri: surah.mediaItem.artUri,
      extras: {
        ...surah.mediaItem.extras ?? {},
        'isDownloaded': surah.isDownloaded,
        'isDownloading': surah.isDownloading,
        'downloadProgress': surah.downloadProgress,
        'downloadId': surah.downloadId,
      },
    );
  }

  /// Convert MediaItem to Surah
  static SurahEntity fromMediaItem(MediaItem mediaItem) {
    return SurahEntity(
      mediaItem: mediaItem,
      isDownloaded: mediaItem.extras?['isDownloaded'] as bool? ?? false,
      isDownloading: mediaItem.extras?['isDownloading'] as bool? ?? false,
      downloadProgress:
          (mediaItem.extras?['downloadProgress'] as num?)?.toDouble() ?? 0.0,
      downloadId: mediaItem.extras?['downloadId'] as String?,
    );
  }

  /// Create Surah from basic data
  static SurahEntity create({
    required String id,
    required String name,
    required String nameAr,
    required String reciterName,
    required String url,
    bool isDownloaded = false,
    bool isDownloading = false,
    double downloadProgress = 0.0,
    String? downloadId,
  }) {
    final mediaItem = MediaItem(
      id: id,
      title: name,
      artist: reciterName,
      album: reciterName,
      duration: null,
      artUri: null,
      extras: {'nameAr': nameAr, 'url': url},
    );

    return SurahEntity(
      mediaItem: mediaItem,
      isDownloaded: isDownloaded,
      isDownloading: isDownloading,
      downloadProgress: downloadProgress,
      downloadId: downloadId,
    );
  }
}
