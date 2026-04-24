import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../entities/audio_clip_config.dart';
import '../entities/share_content.dart';
import '../entities/share_progress_messages.dart';
import '../repositories/share_repository.dart';

@injectable
class GenerateAudioClipUseCase {
  GenerateAudioClipUseCase(this._repository);
  final ShareRepository _repository;

  Future<ShareContent> call({
    required AudioClipConfig config,
    required AudioClipProgressMessages progressMessages,
    int? maxDurationSeconds,
    void Function(double progress, String message)? onProgress,
    CancelToken? cancelToken,
  }) {
    return _repository.generateAudioClip(
      config: config,
      progressMessages: progressMessages,
      maxDurationSeconds: maxDurationSeconds,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }
}
