import 'dart:async';

import 'package:tilawa/features/share/data/ffmpeg/ffmpeg_runner.dart';

/// Programmable fake [FFmpegRunner] for unit tests.
///
/// Records every command issued so tests can assert on the exact ffmpeg
/// invocation, and lets each call site script its own outcome (success,
/// failure, cancel, throw) plus a stream of stats snapshots delivered to the
/// async-stats callback.
class FakeFFmpegRunner implements FFmpegRunner {
  /// FIFO queue of `execute()` outcomes. Each call pops the head; if empty,
  /// the configured [defaultExecuteResult] is returned.
  final List<FFmpegRunResult> executeResults = <FFmpegRunResult>[];

  /// FIFO queue of `executeAsync()` plans. Each call pops the head; if empty,
  /// the configured [defaultAsyncPlan] is used.
  final List<FakeAsyncPlan> asyncPlans = <FakeAsyncPlan>[];

  /// FIFO queue of `getMediaInformation()` outcomes. Each call pops the head;
  /// if empty, the configured [defaultMediaInfo] is returned.
  final List<FFmpegMediaInfo?> mediaInfoResults = <FFmpegMediaInfo?>[];

  FFmpegRunResult defaultExecuteResult = const FFmpegRunResult(
    status: FFmpegRunStatus.success,
  );
  FakeAsyncPlan defaultAsyncPlan = FakeAsyncPlan.success();
  FFmpegMediaInfo? defaultMediaInfo;

  /// Every command passed to `execute()`, in order.
  final List<String> executeCommands = <String>[];

  /// Every command passed to `executeAsync()`, in order.
  final List<String> asyncCommands = <String>[];

  /// Every path passed to `getMediaInformation()`, in order.
  final List<String> mediaInfoPaths = <String>[];

  /// All async-handle objects this fake handed out, in creation order.
  /// Tests use these to invoke `cancel()` mid-flight.
  final List<FakeAsyncHandle> handles = <FakeAsyncHandle>[];

  Object? throwOnExecute;
  Object? throwOnExecuteAsync;
  Object? throwOnGetMediaInformation;

  /// Hook invoked synchronously when `executeAsync()` is called, before the
  /// plan starts ticking. Tests use this to simulate side-effects of a real
  /// encoder run — most commonly, writing a stand-in output file at the
  /// service-chosen path so the post-encode validation can succeed.
  void Function(String command)? onAsyncCommand;

  @override
  Future<FFmpegRunResult> execute(String command) async {
    executeCommands.add(command);
    if (throwOnExecute != null) throw throwOnExecute!;
    if (executeResults.isNotEmpty) return executeResults.removeAt(0);
    return defaultExecuteResult;
  }

  @override
  Future<FFmpegRunHandle> executeAsync(
    String command, {
    void Function(FFmpegStatsSnapshot stats)? onStats,
  }) async {
    asyncCommands.add(command);
    if (throwOnExecuteAsync != null) throw throwOnExecuteAsync!;
    onAsyncCommand?.call(command);
    final plan = asyncPlans.isNotEmpty
        ? asyncPlans.removeAt(0)
        : defaultAsyncPlan;
    final handle = FakeAsyncHandle(plan: plan, onStats: onStats);
    handles.add(handle);
    // Schedule plan execution on a microtask so the caller can register
    // `cancelToken` listeners before the plan starts emitting stats.
    scheduleMicrotask(handle._start);
    return handle;
  }

  @override
  Future<FFmpegMediaInfo?> getMediaInformation(String path) async {
    mediaInfoPaths.add(path);
    if (throwOnGetMediaInformation != null) throw throwOnGetMediaInformation!;
    if (mediaInfoResults.isNotEmpty) return mediaInfoResults.removeAt(0);
    return defaultMediaInfo;
  }
}

/// Script for one `executeAsync()` call: the stats ticks to deliver before
/// completion, and the final result. If [respectCancel] is true (the default),
/// calling `cancel()` short-circuits to a cancelled result without delivering
/// the trailing stats.
class FakeAsyncPlan {
  FakeAsyncPlan({
    required this.result,
    this.stats = const <FFmpegStatsSnapshot>[],
    this.respectCancel = true,
    this.manualCompletion = false,
  });

  factory FakeAsyncPlan.success({
    List<FFmpegStatsSnapshot> stats = const <FFmpegStatsSnapshot>[],
  }) => FakeAsyncPlan(
    result: const FFmpegRunResult(status: FFmpegRunStatus.success),
    stats: stats,
  );

  factory FakeAsyncPlan.failure({
    String logs = '',
    List<FFmpegStatsSnapshot> stats = const <FFmpegStatsSnapshot>[],
  }) => FakeAsyncPlan(
    result: FFmpegRunResult(status: FFmpegRunStatus.failure, logs: logs),
    stats: stats,
  );

  factory FakeAsyncPlan.cancelled({
    List<FFmpegStatsSnapshot> stats = const <FFmpegStatsSnapshot>[],
  }) => FakeAsyncPlan(
    result: const FFmpegRunResult(status: FFmpegRunStatus.cancelled),
    stats: stats,
  );

  final FFmpegRunResult result;
  final List<FFmpegStatsSnapshot> stats;
  final bool respectCancel;

  /// When true, [FakeAsyncHandle._start] delivers the scripted [stats] but
  /// does NOT auto-complete the [done] future. Use this for tests that need
  /// the plan to stay pending until something external (e.g. a cancel
  /// signal) advances it.
  final bool manualCompletion;
}

class FakeAsyncHandle implements FFmpegRunHandle {
  FakeAsyncHandle({
    required FakeAsyncPlan plan,
    required void Function(FFmpegStatsSnapshot stats)? onStats,
  }) : _plan = plan,
       _onStats = onStats;

  static int _nextSessionId = 1;

  final FakeAsyncPlan _plan;
  final void Function(FFmpegStatsSnapshot stats)? _onStats;
  final Completer<FFmpegRunResult> _completer = Completer<FFmpegRunResult>();

  bool cancelCalled = false;

  @override
  final int sessionId = _nextSessionId++;

  @override
  Future<FFmpegRunResult> get done => _completer.future;

  @override
  void cancel() {
    cancelCalled = true;
    if (_plan.respectCancel && !_completer.isCompleted) {
      _completer.complete(
        const FFmpegRunResult(status: FFmpegRunStatus.cancelled),
      );
    }
  }

  void _start() {
    for (final stat in _plan.stats) {
      if (_completer.isCompleted) return; // cancelled mid-flight
      _onStats?.call(stat);
    }
    if (!_plan.manualCompletion && !_completer.isCompleted) {
      _completer.complete(_plan.result);
    }
  }
}
