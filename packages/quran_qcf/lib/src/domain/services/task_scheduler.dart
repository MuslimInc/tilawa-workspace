import 'dart:async';

/// Represents a scheduled task that can be cancelled before execution.
abstract class ScheduledTask {
  /// Whether this task was cancelled before execution.
  bool get isCancelled;

  /// Whether this task has completed (either executed or cancelled).
  bool get isCompleted;

  /// Cancels the task if not yet running.
  void cancel();

  /// A future that completes when the task finishes or is cancelled.
  Future<void> get future;
}

/// Repository interface for scheduling GPU-intensive tasks during idle frames.
///
/// Abstracts idle frame scheduling to ensure expensive operations like
/// bitmap captures never compete with live frame rasterization.
abstract class TaskScheduler {
  /// Schedules [task] to run after the current frame completes and no other
  /// idle task is active. Returns a handle for cancellation.
  ScheduledTask runWhenIdle(Future<void> Function() task);

  /// Cancels all pending tasks. Tasks already running will complete.
  void cancelAll();
}
