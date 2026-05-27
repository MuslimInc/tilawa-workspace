import '../entities/audio_clip_config.dart';
import '../entities/share_cancel_token.dart';
import '../entities/share_content.dart';
import '../entities/share_footer_colors.dart';
import '../entities/share_progress_messages.dart';
import '../entities/widget_capture_handle.dart';

/// Abstract interface for share operations.
abstract class ShareRepository {
  /// Captures the current Quran page as a branded screenshot.
  Future<ShareContent> captureScreenshot({
    required WidgetCaptureHandle handle,
    required String surahName,
    required int pageNumber,
    required String appName,
    required String sharedViaLabel,
    bool brandCapture = true,
    ShareFooterColors? footerColors,
  });

  /// Generates an audio clip for the given verse range and reciter.
  Future<ShareContent> generateAudioClip({
    required AudioClipConfig config,
    required AudioClipProgressMessages progressMessages,
    int? maxDurationSeconds,
    void Function(double progress, String message)? onProgress,
    ShareCancelToken? cancelToken,
  });

  /// Captures screenshots AND generates an audio clip, then merges them into a video (vertical format).
  Future<ShareContent> generateVideo({
    required List<WidgetCaptureHandle> handles,
    required AudioClipConfig config,
    required String appName,
    required String sharedViaLabel,
    required ShareProgressMessages progressMessages,
    int? maxDurationSeconds,
    void Function(double progress, String message)? onProgress,
    void Function(int index)? onFrameCaptureStarted,
    ShareCancelToken? cancelToken,
  });

  /// Shares the given content via the native share sheet.
  Future<void> shareContent(ShareContent content);

  /// Exports a persistent copy of generated media and returns its new path.
  Future<String> exportContent(ShareContent content);

  /// Cleans up temporary share files.
  Future<void> cleanup();
}
