import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../features/downloads/domain/entities/download_item.dart';
import '../../../../features/downloads/domain/repositories/download_query_repository.dart';
import '../../domain/entities/audio_clip_config.dart';
import '../../domain/entities/share_content.dart';
import '../../domain/entities/share_progress_messages.dart';
import '../../domain/repositories/share_repository.dart';
import '../services/audio_clip_service.dart';
import '../services/share_file_manager.dart';
import '../services/screenshot_service.dart';
import '../services/video_service.dart';

@LazySingleton(as: ShareRepository)
class ShareRepositoryImpl implements ShareRepository {
  ShareRepositoryImpl(
    this._screenshotService,
    this._audioClipService,
    this._videoService,
    this._fileManager,
    this._downloadQueryRepository,
  );

  final ScreenshotService _screenshotService;
  final AudioClipService _audioClipService;
  final VideoService _videoService;
  final ShareFileManager _fileManager;
  final DownloadQueryRepository _downloadQueryRepository;

  @override
  Future<ShareContent> captureScreenshot({
    required GlobalKey boundaryKey,
    required String surahName,
    required int pageNumber,
    required String appName,
    required String sharedViaLabel,
    bool brandCapture = true,
  }) async {
    await WidgetsBinding.instance.endOfFrame;
    final filePath = brandCapture
        ? await _screenshotService.captureAndBrand(
            boundaryKey: boundaryKey,
            surahName: surahName,
            pageNumber: pageNumber,
            appName: appName,
            sharedViaLabel: sharedViaLabel,
          )
        : await _screenshotService.captureRaw(
            boundaryKey: boundaryKey,
            fileName:
                'share_capture_${DateTime.now().millisecondsSinceEpoch}.png',
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
    required AudioClipProgressMessages progressMessages,
    int? maxDurationSeconds,
    void Function(double progress, String message)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final effectiveConfig = await _audioClipService.resolveConfigForDuration(
      config: config,
      maxDurationSeconds: maxDurationSeconds,
    );
    final List<DownloadItem> allDownloads = await _downloadQueryRepository
        .getAllDownloads();
    // Build a URL→item map for O(1) lookup instead of a linear scan.
    final Map<String, DownloadItem> downloadsByUrl = {
      for (final d in allDownloads) d.url: d,
    };
    final DownloadItem? localDownload =
        downloadsByUrl[effectiveConfig.serverUrl];

    final filePath = await _audioClipService.generateAudioClip(
      effectiveConfig,
      localSurahPath: localDownload?.filePath,
      progressMessages: progressMessages,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
    return ShareContent.audioClip(
      filePath: filePath,
      surahName: '', // Will be filled by the cubit with localized name
      fromAyah: effectiveConfig.fromAyah,
      toAyah: effectiveConfig.toAyah,
      reciterName: effectiveConfig.reciterName,
    );
  }

  @override
  Future<ShareContent> generateVideo({
    required List<GlobalKey> boundaryKeys,
    required AudioClipConfig config,
    required String appName,
    required String sharedViaLabel,
    required ShareProgressMessages progressMessages,
    int? maxDurationSeconds,
    void Function(double progress, String message)? onProgress,
    void Function(int index)? onFrameCaptureStarted,
    CancelToken? cancelToken,
  }) async {
    final effectiveBoundaryKeys = boundaryKeys;
    final effectiveConfig = await _audioClipService.resolveConfigForDuration(
      config: config,
      maxDurationSeconds: maxDurationSeconds,
    );

    onProgress?.call(0.1, progressMessages.generatingAudioClip);

    // 1. Generate audio clip (independent of screenshots).
    final audioContent = await generateAudioClip(
      config: effectiveConfig,
      progressMessages: progressMessages.audioClip,
      onProgress: (p, msg) => onProgress?.call(0.1 + p * 0.35, msg),
      cancelToken: cancelToken,
    );

    // 2. Capture screenshots sequentially.
    // Capturing screenshots is a heavy GPU operation (RepaintBoundary.toImage).
    // Running them in parallel via Future.wait causes massive raster jank
    // and high memory pressure. Serializing them stabilizes the frame rate.
    final List<String> screenshotPaths = [];
    final double captureBaseProgress = 0.45;
    final double captureStep = 0.15 / effectiveBoundaryKeys.length;

    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < effectiveBoundaryKeys.length; i++) {
      if (cancelToken?.isCancelled ?? false) break;

      // Notify the UI to render the current frame before we capture it.
      onFrameCaptureStarted?.call(i);

      // Yield to the UI thread before each capture to allow the progress bar
      // and other UI elements to animate smoothly.
      await WidgetsBinding.instance.endOfFrame;

      final path = await _screenshotService.captureRaw(
        boundaryKey: effectiveBoundaryKeys[i],
        fileName: 'video_capture_${timestamp}_${i + 1}.png',
        pixelRatio: 1.0,
        targetWidth: VideoService.outputVideoWidth,
        targetHeight: VideoService.outputVideoHeight,
      );
      screenshotPaths.add(path);

      onProgress?.call(
        captureBaseProgress + (i + 1) * captureStep,
        progressMessages.capturingReaderVisuals,
      );
    }

    // 2. Generate video
    onProgress?.call(0.6, progressMessages.combiningVideoMedia);
    final videoPath = await _videoService.generateVideo(
      screenshotPaths: screenshotPaths,
      audioPath: audioContent.filePath,
      surahName: '', // Metadata
      reciterName: effectiveConfig.reciterName,
      progressMessages: progressMessages.video,
      onProgress: (p, msg) => onProgress?.call(0.6 + p * 0.4, msg),
      cancelToken: cancelToken,
    );

    return ShareContent.video(
      filePath: videoPath,
      surahName: '',
      fromAyah: effectiveConfig.fromAyah,
      toAyah: effectiveConfig.toAyah,
      reciterName: effectiveConfig.reciterName,
    );
  }

  @override
  Future<void> shareContent(ShareContent content) async {
    if (content case ShareText(:final text)) {
      await SharePlus.instance.share(ShareParams(text: text));
      return;
    }

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
      ShareVideo(
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
      ShareText() => throw UnimplementedError(),
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
