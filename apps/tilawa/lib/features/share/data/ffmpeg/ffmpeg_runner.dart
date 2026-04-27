/// Plugin-agnostic seam over the FFmpeg/FFprobe runtime.
///
/// The data layer depends on this port; the concrete `FfmpegKitRunner` adapter
/// wraps `ffmpeg_kit_flutter_new`. Keeping plugin types out of this file is the
/// whole point — it lets `VideoService` stay decoupled from the encoder backend
/// and lets unit tests substitute a deterministic fake.
library;

/// Outcome of an FFmpeg session, normalised across plugin return-code types.
enum FFmpegRunStatus { success, failure, cancelled }

/// Immutable result of a one-shot or async FFmpeg run.
///
/// [logs] is the concatenated session log (newline-joined). It is empty on
/// success — the adapter only materialises logs when the run did not succeed,
/// matching the production code path that inspects them for failure-classification.
class FFmpegRunResult {
  const FFmpegRunResult({required this.status, this.logs = ''});

  final FFmpegRunStatus status;
  final String logs;

  bool get isSuccess => status == FFmpegRunStatus.success;
  bool get isCancelled => status == FFmpegRunStatus.cancelled;
}

/// Handle to a still-running async FFmpeg session.
abstract interface class FFmpegRunHandle {
  /// Native session id used to address the running process for cancellation.
  int get sessionId;

  /// Completes when the session terminates, regardless of outcome.
  Future<FFmpegRunResult> get done;

  /// Best-effort cancel. Fire-and-forget — preserved verbatim from the original
  /// `FFmpegKit.cancel(sessionId)` call site, which intentionally swallowed errors.
  void cancel();
}

/// Single statistics tick from an async session. Currently the service only
/// reads encoded-time-ms; if more fields become useful, add them here rather
/// than leaking the plugin's `Statistics` type.
class FFmpegStatsSnapshot {
  const FFmpegStatsSnapshot({required this.timeMs});

  final int timeMs;
}

/// Plugin-agnostic media probe result. `null` duration means ffprobe could not
/// determine one; callers fall back to a slide-count heuristic.
class FFmpegMediaInfo {
  const FFmpegMediaInfo({this.durationSeconds});

  final double? durationSeconds;
}

/// Port the data layer depends on. The default production binding is
/// `FfmpegKitRunner` (registered via injectable as `@LazySingleton(as: FFmpegRunner)`).
abstract interface class FFmpegRunner {
  /// Runs [command] to completion and returns the result. Used for short
  /// one-shot operations like raw-frame → PNG extraction.
  Future<FFmpegRunResult> execute(String command);

  /// Starts [command] asynchronously, streaming progress through [onStats]
  /// while it runs. The returned handle resolves with the final result.
  Future<FFmpegRunHandle> executeAsync(
    String command, {
    void Function(FFmpegStatsSnapshot stats)? onStats,
  });

  /// Probes [path] for media metadata. Returns `null` if probing fails.
  Future<FFmpegMediaInfo?> getMediaInformation(String path);
}
