import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../entities/audio_clip_config.dart';
import '../entities/share_content.dart';
import '../entities/share_progress_messages.dart';
import '../entities/widget_capture_handle.dart';
import '../repositories/share_repository.dart';

@injectable
class GenerateVideoUseCase {
  GenerateVideoUseCase(this._repository);

  final ShareRepository _repository;

  Future<ShareContent> call({
    required List<WidgetCaptureHandle> handles,
    required AudioClipConfig config,
    required String appName,
    required String sharedViaLabel,
    required ShareProgressMessages progressMessages,
    int? maxDurationSeconds,
    void Function(double progress, String message)? onProgress,
    void Function(int index)? onFrameCaptureStarted,
    CancelToken? cancelToken,
  }) {
    return _repository.generateVideo(
      handles: handles,
      config: config,
      appName: appName,
      sharedViaLabel: sharedViaLabel,
      progressMessages: progressMessages,
      maxDurationSeconds: maxDurationSeconds,
      onProgress: onProgress,
      onFrameCaptureStarted: onFrameCaptureStarted,
      cancelToken: cancelToken,
    );
  }
}
