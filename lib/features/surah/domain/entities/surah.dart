import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';

class Surah extends Equatable {
  const Surah({
    required this.mediaItem,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.downloadId,
  });

  final MediaItem mediaItem;
  final bool isDownloaded;
  final bool isDownloading;
  final double downloadProgress; // 0.0 to 1.0
  final String? downloadId;

  // Convenience getters for easy access to MediaItem properties
  String get id => mediaItem.id;
  String get name => mediaItem.title;
  String get nameAr => mediaItem.extras?['nameAr'] as String? ?? '';
  String get reciterName => mediaItem.artist ?? '';
  String get url => mediaItem.extras?['url'] as String? ?? '';

  Surah copyWith({
    MediaItem? mediaItem,
    bool? isDownloaded,
    bool? isDownloading,
    double? downloadProgress,
    String? downloadId,
  }) {
    return Surah(
      mediaItem: mediaItem ?? this.mediaItem,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadId: downloadId ?? this.downloadId,
    );
  }

  @override
  List<Object?> get props => [
    mediaItem,
    isDownloaded,
    isDownloading,
    downloadProgress,
    downloadId,
  ];

  @override
  String toString() {
    return 'Surah(mediaItem: $mediaItem, isDownloaded: $isDownloaded, isDownloading: $isDownloading, '
        'downloadProgress: $downloadProgress, downloadId: $downloadId)';
  }
}
