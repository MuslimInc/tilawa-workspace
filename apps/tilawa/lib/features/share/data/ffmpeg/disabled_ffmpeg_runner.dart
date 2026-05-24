import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../presentation/utils/share_feature_flags.dart';
import 'ffmpeg_runner.dart';

/// Production [FFmpegRunner] when native FFmpeg is frozen/disabled.
///
/// Keeps [VideoService] and audio-clip code paths compilable without shipping
/// `ffmpeg_kit_flutter_new`. Swap the injectable binding to
/// `FfmpegKitRunner` (see `apps/tilawa/frozen/share/`) after re-adding the
/// plugin to `pubspec.yaml`.
@LazySingleton(as: FFmpegRunner)
class DisabledFfmpegRunner implements FFmpegRunner {
  const DisabledFfmpegRunner();

  static const String _message =
      'Native FFmpeg is frozen in this build. See apps/tilawa/frozen/share/ '
      'to re-enable video reel encoding.';

  @override
  Future<FFmpegRunResult> execute(String command) async {
    if (kShareFfmpegNativeEnabled) {
      throw StateError(_message);
    }
    return const FFmpegRunResult(
      status: FFmpegRunStatus.failure,
      logs: _message,
    );
  }

  @override
  Future<FFmpegRunHandle> executeAsync(
    String command, {
    void Function(FFmpegStatsSnapshot stats)? onStats,
  }) async {
    if (kShareFfmpegNativeEnabled) {
      throw StateError(_message);
    }
    return _DisabledRunHandle();
  }

  @override
  Future<FFmpegMediaInfo?> getMediaInformation(String path) async => null;
}

class _DisabledRunHandle implements FFmpegRunHandle {
  @override
  int get sessionId => -1;

  @override
  Future<FFmpegRunResult> get done async => const FFmpegRunResult(
    status: FFmpegRunStatus.failure,
    logs: DisabledFfmpegRunner._message,
  );

  @override
  void cancel() {}
}
