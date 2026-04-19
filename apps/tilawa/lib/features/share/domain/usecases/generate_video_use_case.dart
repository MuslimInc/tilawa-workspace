import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart' show GlobalKey;
import 'package:injectable/injectable.dart';
import '../entities/audio_clip_config.dart';
import '../entities/share_content.dart';
import '../entities/share_progress_messages.dart';
import '../repositories/share_repository.dart';

@injectable
class GenerateVideoUseCase {
  GenerateVideoUseCase(this._repository);

  final ShareRepository _repository;

  Future<ShareContent> call({
    required List<GlobalKey> boundaryKeys,
    required AudioClipConfig config,
    required String appName,
    required String sharedViaLabel,
    required ShareProgressMessages progressMessages,
    int? maxDurationSeconds,
    void Function(double progress, String message)? onProgress,
    CancelToken? cancelToken,
  }) {
    return _repository.generateVideo(
      boundaryKeys: boundaryKeys,
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
