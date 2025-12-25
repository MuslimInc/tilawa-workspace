import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/download_item.dart';
import '../services/download_service.dart';

/// Download progress information.
///
/// Emitted by [DownloadService] to notify about download state changes.
///
/// Fields:
/// - `id`: The download identifier (typically the URL).
/// - `status`: Current download status (pending, downloading, completed, etc.).
/// - `progress`: Download progress as a fraction (0.0 to 1.0).
/// - `downloadedSize`: Bytes downloaded (not fully populated by flutter_downloader).
/// - `fileSize`: Total file size in bytes (not fully populated by flutter_downloader).
@immutable
class DownloadProgress extends Equatable {
  const DownloadProgress({
    required this.id,
    required this.status,
    required this.progress,
    required this.downloadedSize,
    required this.fileSize,
  });

  final String id;
  final DownloadStatus status;
  final double progress;
  final int downloadedSize;
  final int fileSize;

  @override
  List<Object?> get props => [id, status, progress, downloadedSize, fileSize];
}
