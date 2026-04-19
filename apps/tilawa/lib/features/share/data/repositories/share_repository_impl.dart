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
    CancelToken? cancelToken,
  }) async {
    final List<GlobalKey> effectiveBoundaryKeys = boundaryKeys
        .where((key) => key.currentContext != null)
        .toList();
    if (effectiveBoundaryKeys.isEmpty) {
      throw StateError(
        'RepaintBoundary not found. Video pages may still be loading.',
      );
    }

    final effectiveConfig = await _audioClipService.resolveConfigForDuration(
      config: config,
      maxDurationSeconds: maxDurationSeconds,
    );

    onProgress?.call(0.1, progressMessages.generatingAudioClip);

    // 1. Capture screenshots and generate audio clip in parallel.
    // Screenshots are a GPU readback (~0.5s) and are independent of audio
    // download/concat, so running them concurrently cuts total wait time.
    await WidgetsBinding.instance.endOfFrame;
    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    final results = await Future.wait<Object>([
      generateAudioClip(
        config: effectiveConfig,
        progressMessages: progressMessages.audioClip,
        onProgress: (p, msg) => onProgress?.call(0.1 + p * 0.35, msg),
        cancelToken: cancelToken,
      ),
      Future.wait<String>([
        for (int index = 0; index < effectiveBoundaryKeys.length; index++)
          _screenshotService.captureRaw(
            boundaryKey: effectiveBoundaryKeys[index],
            fileName: 'video_capture_${timestamp}_${index + 1}.png',
            // Capture at the exact FFmpeg output resolution so the encoder
            // streams frames straight into x264 — no per-frame scale/crop.
            // pixelRatio is still honored as a fallback if the boundary has
            // no measurable size yet.
            pixelRatio: 1.0,
            targetWidth: VideoService.outputVideoWidth,
            targetHeight: VideoService.outputVideoHeight,
          ),
      ]),
    ]);

    final audioContent = results[0] as ShareContent;
    final List<String> screenshotPaths = (results[1] as List).cast<String>();

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
