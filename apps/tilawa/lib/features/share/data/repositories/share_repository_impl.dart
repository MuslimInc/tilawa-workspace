import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tilawa/features/share/domain/entities/widget_capture_handle.dart';

import '../../../../features/downloads/domain/entities/download_item.dart';
import '../../../../features/downloads/domain/repositories/download_query_repository.dart';
import '../../domain/entities/audio_clip_config.dart';
import '../../domain/entities/share_content.dart';
import '../../domain/entities/share_progress_messages.dart';
import '../../domain/repositories/share_repository.dart';
import '../services/audio_clip_service.dart';
import '../services/screenshot_service.dart';
import '../services/share_file_manager.dart';
import '../services/video_service.dart';
import 'package:tilawa_core/logger.dart';

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
  static const double _videoAudioStartProgress = 0.1;
  static const double _videoAudioProgressShare = 0.35;
  static const double _videoCaptureBaseProgress = 0.45;
  static const double _videoCaptureProgressShare = 0.15;
  static const double _videoEncodeStartProgress = 0.6;
  static const double _videoEncodeProgressShare = 0.4;

  @override
  Future<ShareContent> captureScreenshot({
    required WidgetCaptureHandle handle,
    required String surahName,
    required int pageNumber,
    required String appName,
    required String sharedViaLabel,
    bool brandCapture = true,
    Color? footerBackgroundColor,
    Color? footerForegroundColor,
  }) async {
    logger.d(
      '[AppLaunch][ShareRepositoryImpl.captureScreenshot]: Start in (${DateTime.now()})',
    );
    final boundaryKey = handle.value as GlobalKey;
    await WidgetsBinding.instance.endOfFrame;
    final filePath = brandCapture
        ? await _screenshotService.captureAndBrand(
            boundaryKey: boundaryKey,
            surahName: surahName,
            pageNumber: pageNumber,
            appName: appName,
            sharedViaLabel: sharedViaLabel,
            footerBackgroundColor: footerBackgroundColor,
            footerForegroundColor: footerForegroundColor,
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
    logger.d(
      '[AppLaunch][ShareRepositoryImpl.generateAudioClip]: Start in (${DateTime.now()})',
    );
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
    required List<WidgetCaptureHandle> handles,
    required AudioClipConfig config,
    required String appName,
    required String sharedViaLabel,
    required ShareProgressMessages progressMessages,
    int? maxDurationSeconds,
    void Function(double progress, String message)? onProgress,
    void Function(int index)? onFrameCaptureStarted,
    CancelToken? cancelToken,
  }) async {
    logger.d(
      '[AppLaunch][ShareRepositoryImpl.generateVideo]: Start in (${DateTime.now()})',
    );
    final effectiveConfig = await _audioClipService.resolveConfigForDuration(
      config: config,
      maxDurationSeconds: maxDurationSeconds,
    );

    onProgress?.call(
      _videoAudioStartProgress,
      progressMessages.generatingAudioClip,
    );

    // 1. Generate audio clip (independent of screenshots).
    final audioContent = await generateAudioClip(
      config: effectiveConfig,
      progressMessages: progressMessages.audioClip,
      onProgress: (p, msg) => onProgress?.call(
        _videoAudioStartProgress + p * _videoAudioProgressShare,
        msg,
      ),
      cancelToken: cancelToken,
    );

    // 2. Capture screenshots sequentially.
    final List<String> screenshotPaths = [];
    final double captureStep = _videoCaptureProgressShare / handles.length;

    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Pre-warm the first page to compile shaders before the capture loop.
    // This prevents the first frame spike by front-loading shader compilation.
    if (handles.isNotEmpty) {
      onFrameCaptureStarted?.call(0);
      await WidgetsBinding.instance.endOfFrame;
    }
    
    for (int i = 0; i < handles.length; i++) {
      if (cancelToken?.isCancelled ?? false) break;

      // Notify the UI to render the current frame before we capture it.
      onFrameCaptureStarted?.call(i);

      // Yield to the UI thread before each capture to allow the progress bar
      // and other UI elements to animate smoothly. Double-yield ensures the
      // GPU has completed shader compilation and rasterization work.
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;

      final boundaryKey = handles[i].value as GlobalKey;
      final path = await _screenshotService.captureRaw(
        boundaryKey: boundaryKey,
        fileName: 'video_capture_${timestamp}_${i + 1}.png',
        pixelRatio: 1.0,
        targetWidth: VideoService.outputVideoWidth,
        targetHeight: VideoService.outputVideoHeight,
      );
      screenshotPaths.add(path);

      onProgress?.call(
        _videoCaptureBaseProgress + (i + 1) * captureStep,
        progressMessages.capturingReaderVisuals,
      );
    }

    // 3. Generate video.
    onProgress?.call(
      _videoEncodeStartProgress,
      progressMessages.combiningVideoMedia,
    );
    final videoPath = await _videoService.generateVideo(
      screenshotPaths: screenshotPaths,
      audioPath: audioContent.filePath,
      surahName: '', // Metadata
      reciterName: effectiveConfig.reciterName,
      progressMessages: progressMessages.video,
      onProgress: (p, msg) => onProgress?.call(
        _videoEncodeStartProgress + p * _videoEncodeProgressShare,
        msg,
      ),
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
    logger.d(
      '[AppLaunch][ShareRepositoryImpl.shareContent]: Start in (${DateTime.now()})',
    );
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
  Future<void> cleanup() {
    logger.d(
      '[AppLaunch][ShareRepositoryImpl.cleanup]: Start in (${DateTime.now()})',
    );
    return _fileManager.cleanup();
  }
}
