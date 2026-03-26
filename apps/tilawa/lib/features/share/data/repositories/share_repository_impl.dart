import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../features/downloads/domain/repositories/download_query_repository.dart';
import '../../domain/entities/audio_clip_config.dart';
import '../../domain/entities/share_content.dart';
import '../../domain/repositories/share_repository.dart';
import '../services/audio_clip_service.dart';
import '../services/reel_service.dart';
import '../services/screenshot_service.dart';
import '../services/share_file_manager.dart';

@LazySingleton(as: ShareRepository)
class ShareRepositoryImpl implements ShareRepository {
  ShareRepositoryImpl(
    this._screenshotService,
    this._audioClipService,
    this._reelService,
    this._fileManager,
    this._downloadQueryRepository,
  );

  final ScreenshotService _screenshotService;
  final AudioClipService _audioClipService;
  final ReelService _reelService;
  final ShareFileManager _fileManager;
  final DownloadQueryRepository _downloadQueryRepository;

  @override
  Future<ShareContent> captureScreenshot({
    required GlobalKey boundaryKey,
    required String surahName,
    required int pageNumber,
    required String appName,
    required String sharedViaLabel,
  }) async {
    final filePath = await _screenshotService.captureAndBrand(
      boundaryKey: boundaryKey,
      surahName: surahName,
      pageNumber: pageNumber,
      appName: appName,
      sharedViaLabel: sharedViaLabel,
    );
    return ShareContent.screenshot(
      filePath: filePath,
      surahName: surahName,
      pageNumber: pageNumber,
    );
  }

  @override
  Future<ShareContent> generateAudioClip({
    required AudioClipConfig config,
    void Function(double progress, String message)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final allDownloads = await _downloadQueryRepository.getAllDownloads();
    final localDownload = allDownloads.cast<dynamic>().firstWhere(
      (d) => d.url == config.serverUrl,
      orElse: () => null,
    );

    final filePath = await _audioClipService.generateAudioClip(
      config,
      localSurahPath: localDownload?.filePath,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
    return ShareContent.audioClip(
      filePath: filePath,
      surahName: '', // Will be filled by the cubit with localized name
      fromAyah: config.fromAyah,
      toAyah: config.toAyah,
      reciterName: config.reciterName,
    );
  }

  @override
  Future<ShareContent> generateReel({
    required GlobalKey<State<StatefulWidget>> boundaryKey,
    required AudioClipConfig config,
    required String appName,
    required String sharedViaLabel,
    void Function(double progress, String message)? onProgress,
    CancelToken? cancelToken,
  }) async {
    // 1. Generate audio clip first (usually faster/more prone to error)
    onProgress?.call(0.1, 'Generating audio clip...');
    final audioContent = await generateAudioClip(
      config: config,
      onProgress: (p, msg) => onProgress?.call(0.1 + p * 0.2, msg),
      cancelToken: cancelToken,
    );

    // 2. Capture screenshot
    onProgress?.call(0.4, 'Capturing reader visuals...');
    final screenshotPath = await _screenshotService.captureAndBrand(
      boundaryKey: boundaryKey,
      surahName: '', // surahName will be taken from metadata later
      pageNumber: 0,
      appName: appName,
      sharedViaLabel: sharedViaLabel,
    );

    // 3. Generate reel video
    onProgress?.call(0.6, 'Combining visuals and audio into a reel...');
    final reelPath = await _reelService.generateReel(
      screenshotPath: screenshotPath,
      audioPath: audioContent.filePath,
      surahName: '', // Metadata
      reciterName: config.reciterName,
      onProgress: (p, msg) => onProgress?.call(0.6 + p * 0.4, msg),
    );

    return ShareContent.reel(
      filePath: reelPath,
      surahName: '',
      fromAyah: config.fromAyah,
      toAyah: config.toAyah,
      reciterName: config.reciterName,
    );
  }

  @override
  Future<void> shareContent(ShareContent content) async {
    final (filePath, text, mimeType) = switch (content) {
      ShareScreenshot(:final filePath, :final surahName, :final pageNumber) => (
        filePath,
        '$surahName — $pageNumber',
        'image/png',
      ),
      ShareAudioClip(
        :final filePath,
        :final surahName,
        :final fromAyah,
        :final toAyah,
        :final reciterName,
      ) =>
        (
          filePath,
          '$surahName ($fromAyah-$toAyah) — $reciterName',
          'audio/mpeg',
        ),
      ShareReel(
        :final filePath,
        :final surahName,
        :final fromAyah,
        :final toAyah,
        :final reciterName,
      ) =>
        (
          filePath,
          '$surahName ($fromAyah-$toAyah) — $reciterName',
          'video/mp4',
        ),
    };

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: mimeType)],
        text: text,
      ),
    );
  }

  @override
  Future<void> cleanup() => _fileManager.cleanup();
}
