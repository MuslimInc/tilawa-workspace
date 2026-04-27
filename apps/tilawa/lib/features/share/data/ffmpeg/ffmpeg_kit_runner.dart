import 'dart:async';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:injectable/injectable.dart';

import 'ffmpeg_runner.dart';

/// Production adapter binding [FFmpegRunner] to `ffmpeg_kit_flutter_new`.
///
/// This is the only file in the data layer that imports the plugin. Every
/// other consumer talks to the [FFmpegRunner] port. Keep delegation in here
/// strictly mechanical — no policy, no progress math, no log parsing.
@LazySingleton(as: FFmpegRunner)
class FfmpegKitRunner implements FFmpegRunner {
  const FfmpegKitRunner();

  @override
  Future<FFmpegRunResult> execute(String command) async {
    final session = await FFmpegKit.execute(command);
    return _toResult(session);
  }

  @override
  Future<FFmpegRunHandle> executeAsync(
    String command, {
    void Function(FFmpegStatsSnapshot stats)? onStats,
  }) async {
    final completer = Completer<FFmpegRunResult>();

    final FFmpegSession session = await FFmpegKit.executeAsync(
      command,
      (finishedSession) async {
        if (completer.isCompleted) return;
        completer.complete(await _toResult(finishedSession));
      },
      null,
      onStats == null
          ? null
          : (stats) => onStats(FFmpegStatsSnapshot(timeMs: stats.getTime())),
    );

    return _KitRunHandle(session: session, done: completer.future);
  }

  @override
  Future<FFmpegMediaInfo?> getMediaInformation(String path) async {
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final info = session.getMediaInformation();
      final durationText = info?.getDuration();
      return FFmpegMediaInfo(
        durationSeconds: durationText == null
            ? null
            : double.tryParse(durationText),
      );
    } catch (_) {
      return null;
    }
  }

  /// Maps a finished [FFmpegSession] to the plugin-agnostic result. Logs are
  /// only joined on non-success to avoid the per-encode allocation cost on the
  /// happy path.
  static Future<FFmpegRunResult> _toResult(FFmpegSession session) async {
    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      return const FFmpegRunResult(status: FFmpegRunStatus.success);
    }
    if (ReturnCode.isCancel(returnCode)) {
      return const FFmpegRunResult(status: FFmpegRunStatus.cancelled);
    }
    final logs = await session.getLogs();
    final joined = logs.map((l) => l.getMessage()).join('\n');
    return FFmpegRunResult(status: FFmpegRunStatus.failure, logs: joined);
  }
}

class _KitRunHandle implements FFmpegRunHandle {
  _KitRunHandle({required this.session, required this.done});

  final FFmpegSession session;

  @override
  final Future<FFmpegRunResult> done;

  @override
  int get sessionId => session.getSessionId() ?? -1;

  @override
  void cancel() {
    // Fire-and-forget. The original `FFmpegKit.cancel(...)` call site
    // intentionally ignored errors via `.catchError((_) {})`; preserved here.
    try {
      FFmpegKit.cancel(session.getSessionId());
    } catch (_) {
      // Swallow — cancel is best-effort.
    }
  }
}
