import 'package:freezed_annotation/freezed_annotation.dart';

part 'download_item.freezed.dart';
part 'download_item.g.dart';

/// Represents a download item with its current state and metadata.
@freezed
abstract class DownloadItem with _$DownloadItem {
  const factory DownloadItem({
    required String id,
    required String title,
    required String url,
    required String filePath,
    required String reciterName,
    int? reciterId,
    required DownloadStatus status,

    /// Progress value from 0.0 to 1.0
    required double progress,

    /// File size in bytes
    required int fileSize,

    /// Downloaded size in bytes
    required int downloadedSize,
    required DateTime createdAt,
    DateTime? completedAt,
  }) = _DownloadItem;

  factory DownloadItem.fromJson(Map<String, dynamic> json) =>
      _$DownloadItemFromJson(json);
}

enum DownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  paused,
  cancelled,
}
