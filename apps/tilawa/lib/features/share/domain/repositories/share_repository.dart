import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import '../entities/audio_clip_config.dart';
import '../entities/share_content.dart';

/// Abstract interface for share operations.
abstract class ShareRepository {
  /// Captures the current Quran page as a branded screenshot.
  Future<ShareContent> captureScreenshot({
    required GlobalKey boundaryKey,
    required String surahName,
    required int pageNumber,
    required String appName,
    required String sharedViaLabel,
    bool brandCapture = true,
  });

  /// Generates an audio clip for the given verse range and reciter.
  Future<ShareContent> generateAudioClip({
    required AudioClipConfig config,
    int? maxDurationSeconds,
    void Function(double progress, String message)? onProgress,
    CancelToken? cancelToken,
  });

  /// Captures a screenshot AND generates an audio clip, then merges them into a reel (vertical video).
  Future<ShareContent> generateReel({
    required GlobalKey boundaryKey,
    required AudioClipConfig config,
    required String appName,
    required String sharedViaLabel,
    int? maxDurationSeconds,
    void Function(double progress, String message)? onProgress,
    CancelToken? cancelToken,
  });

  /// Shares the given content via the native share sheet.
  Future<void> shareContent(ShareContent content);

  /// Cleans up temporary share files.
  Future<void> cleanup();
}
