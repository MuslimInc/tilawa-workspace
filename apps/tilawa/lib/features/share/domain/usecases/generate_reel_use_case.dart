import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import '../entities/audio_clip_config.dart';
import '../entities/share_content.dart';
import '../entities/share_progress_messages.dart';
import '../repositories/share_repository.dart';

@injectable
class GenerateReelUseCase {
  GenerateReelUseCase(this._repository);

  final ShareRepository _repository;

  Future<ShareContent> call({
    required GlobalKey boundaryKey,
    required AudioClipConfig config,
    required String appName,
    required String sharedViaLabel,
    required ShareProgressMessages progressMessages,
    int? maxDurationSeconds,
    void Function(double progress, String message)? onProgress,
    CancelToken? cancelToken,
  }) {
    return _repository.generateReel(
      boundaryKey: boundaryKey,
      config: config,
      appName: appName,
      sharedViaLabel: sharedViaLabel,
      progressMessages: progressMessages,
      maxDurationSeconds: maxDurationSeconds,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }
}
