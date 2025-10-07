import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:muzakri/features/downloads/data/datasources/downloads_local_datasource.dart';
import 'package:muzakri/features/downloads/data/services/download_service.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:path/path.dart' as path;

class DownloadsRepositoryImpl implements DownloadsRepository {
  const DownloadsRepositoryImpl({required this.localDataSource});

  final DownloadsLocalDataSource localDataSource;

  @override
  Future<Map<String, List<DownloadItem>>> getDownloadsByReciter() async {
    final downloads = await localDataSource.getDownloads();
    final Map<String, List<DownloadItem>> grouped = {};

    for (final download in downloads) {
      if (!grouped.containsKey(download.reciterName)) {
        grouped[download.reciterName] = [];
      }
      grouped[download.reciterName]!.add(download);
    }

    return grouped;
  }

  @override
  Future<List<DownloadItem>> getDownloadsForReciter(String reciterName) async {
    final downloads = await localDataSource.getDownloads();
    return downloads.where((d) => d.reciterName == reciterName).toList();
  }

  @override
  Future<DownloadItem?> getDownloadItem(String id) async {
    final downloads = await localDataSource.getDownloads();
    try {
      return downloads.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> addDownload(DownloadItem downloadItem) async {
    await localDataSource.addDownload(downloadItem);
  }

  @override
  Future<void> updateDownload(DownloadItem downloadItem) async {
    await localDataSource.updateDownload(downloadItem);
  }

  @override
  Future<void> deleteDownload(String id) async {
    final download = await getDownloadItem(id);
    if (download != null &&
        await localDataSource.isFileExists(download.filePath)) {
      await localDataSource.deleteFile(download.filePath);
    }
    await localDataSource.deleteDownload(id);
  }

  @override
  Future<void> deleteDownloadsForReciter(String reciterName) async {
    final downloads = await getDownloadsForReciter(reciterName);
    for (final download in downloads) {
      await deleteDownload(download.id);
    }
  }

  @override
  Future<void> clearAllDownloads() async {
    final downloads = await localDataSource.getDownloads();
    for (final download in downloads) {
      if (await localDataSource.isFileExists(download.filePath)) {
        await localDataSource.deleteFile(download.filePath);
      }
    }
    await localDataSource.clearAllDownloads();
  }

  @override
  Stream<DownloadItem> getDownloadProgress(String id) async* {
    // This would typically be implemented with a download manager
    // For now, we'll simulate progress updates
    final download = await getDownloadItem(id);
    if (download != null) {
      yield download;
    }
  }

  @override
  Future<void> startDownload(
    String surahId,
    String surahTitle,
    String reciterName,
    String url,
  ) async {
    final downloadsDir = await localDataSource.getDownloadsDirectory();
    final fileName = '${surahId}_${reciterName.replaceAll(' ', '_')}.mp3';
    final filePath = path.join(downloadsDir, fileName);

    final downloadItem = DownloadItem(
      id: '${surahId}_${reciterName}_${DateTime.now().millisecondsSinceEpoch}',
      title: surahTitle,
      url: url,
      filePath: filePath,
      reciterName: reciterName,
      status: DownloadStatus.pending,
      progress: 0.0,
      fileSize: 0,
      downloadedSize: 0,
      createdAt: DateTime.now(),
    );

    await addDownload(downloadItem);

    // Start the download in background isolate
    await DownloadService.startDownload(
      id: downloadItem.id,
      url: url,
      filePath: filePath,
      title: surahTitle,
      reciterName: reciterName,
    );
  }

  @override
  Future<void> pauseDownload(String id) async {
    // Pause functionality not implemented in new DownloadService
    // Downloads run to completion in individual isolates
    final download = await getDownloadItem(id);
    if (download != null) {
      final updatedDownload = download.copyWith(status: DownloadStatus.paused);
      await updateDownload(updatedDownload);
    }
  }

  @override
  Future<void> resumeDownload(String id) async {
    // Resume functionality not implemented in new DownloadService
    // Downloads run to completion in individual isolates
    final download = await getDownloadItem(id);
    if (download != null) {
      final updatedDownload = download.copyWith(
        status: DownloadStatus.downloading,
      );
      await updateDownload(updatedDownload);
    }
  }

  @override
  Future<void> cancelDownload(String id) async {
    await DownloadService.cancelDownload(id);

    final download = await getDownloadItem(id);
    if (download != null) {
      final updatedDownload = download.copyWith(
        status: DownloadStatus.cancelled,
      );
      await updateDownload(updatedDownload);
      if (await localDataSource.isFileExists(download.filePath)) {
        await localDataSource.deleteFile(download.filePath);
      }
    }
  }

  @override
  Future<bool> isSurahDownloaded(String surahId, String reciterName) async {
    final downloads = await localDataSource.getDownloads();
    for (final d in downloads) {
      final isFileExists = await localDataSource.isFileExists(d.filePath);
      if (d.reciterName == reciterName &&
          d.title.contains(surahId) &&
          d.status == DownloadStatus.completed &&
          isFileExists) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<String?> getDownloadedFilePath(
    String surahId,
    String reciterName,
  ) async {
    final downloads = await localDataSource.getDownloads();
    final download = downloads.firstWhere(
      (d) =>
          d.reciterName == reciterName &&
          d.title.contains(surahId) &&
          d.status == DownloadStatus.completed,
      orElse: () => throw StateError('Download not found'),
    );

    if (await localDataSource.isFileExists(download.filePath)) {
      return download.filePath;
    }
    return null;
  }

  @override
  Future<void> updateDownloadProgress(
    String id,
    DownloadStatus status,
    double progress,
    int downloadedSize,
    int fileSize,
  ) async {
    final download = await getDownloadItem(id);
    if (download != null) {
      final updatedDownload = download.copyWith(
        status: status,
        progress: progress,
        downloadedSize: downloadedSize,
        fileSize: fileSize,
        completedAt: status == DownloadStatus.completed ? DateTime.now() : null,
      );
      await updateDownload(updatedDownload);
    }
  }

  @override
  MediaItem createMediaItemFromDownload(DownloadItem download) {
    // Convert file path to proper file:// URI
    final fileUri = Uri.file(download.filePath).toString();

    return MediaItem(
      id: fileUri,
      title: download.title,
      artist: download.reciterName,
      album: 'Downloaded',
      duration: null, // Duration will be determined by the audio player
      artUri: null,
      extras: {
        'isDownloaded': true,
        'localFilePath': download.filePath,
        'downloadId': download.id,
      },
    );
  }

  @override
  Future<bool> validateDownloadedFile(DownloadItem download) async {
    try {
      final file = File(download.filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<DownloadItem>> getValidCompletedDownloads(
    String reciterName,
  ) async {
    final downloads = await getDownloadsForReciter(reciterName);
    final validDownloads = <DownloadItem>[];

    for (final download in downloads) {
      if (download.status == DownloadStatus.completed) {
        final fileExists = await validateDownloadedFile(download);
        if (fileExists) {
          validDownloads.add(download);
        }
      }
    }

    return validDownloads;
  }

  @override
  List<MediaItem> createMediaItemsFromDownloads(List<DownloadItem> downloads) {
    return downloads.map(createMediaItemFromDownload).toList();
  }
}
