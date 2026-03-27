import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../entities/audio_clip_config.dart';
import '../entities/share_content.dart';
import '../repositories/share_repository.dart';

@injectable
class GenerateAudioClipUseCase {
  GenerateAudioClipUseCase(this._repository);
  final ShareRepository _repository;

  Future<ShareContent> call({
    required AudioClipConfig config,
    int? maxDurationSeconds,
    void Function(double progress, String message)? onProgress,
    CancelToken? cancelToken,
  }) {
    return _repository.generateAudioClip(
      config: config,
      maxDurationSeconds: maxDurationSeconds,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }
}
