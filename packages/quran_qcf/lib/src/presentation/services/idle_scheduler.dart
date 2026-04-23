import 'dart:async';
import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter/scheduler.dart';

/// A handle returned by [IdleScheduler.runWhenIdle] that can cancel the
/// pending task before it executes.
class IdleTask {
  IdleTask._(this._completer, this._scheduler);

  final Completer<void> _completer;
  final IdleScheduler _scheduler;
  bool _cancelled = false;

  /// Whether this task was cancelled before execution.
  bool get isCancelled => _cancelled;

  /// Whether this task has completed (either executed or cancelled).
  bool get isCompleted => _completer.isCompleted;

  /// Cancels the task. If it is not yet running, it will be removed from the
  /// queue and never execute. If already running or completed, this is a no-op.
  void cancel() {
    if (_cancelled || _completer.isCompleted) return;
    _cancelled = true;
    _scheduler._remove(this);
    if (!_completer.isCompleted) _completer.complete();
  }

  /// A future that completes when the task finishes or is cancelled.
  Future<void> get future => _completer.future;
}

/// Schedules tasks to run during verified idle frames so expensive GPU
/// operations like `toImage()` never compete with live frame rasterization.
///
/// Only one task executes at a time, enforcing serial access to the GPU
/// raster thread. Tasks are processed in FIFO order.
///
/// Usage:
/// ```dart
/// final task = idleScheduler.runWhenIdle(() async {
///   await renderObject.toImage(pixelRatio: 3.0);
/// });
/// // Later, if no longer needed:
/// task.cancel();
/// ```
class IdleScheduler {
  final Queue<_QueueEntry> _queue = Queue<_QueueEntry>();
  bool _processing = false;

  /// Schedules [task] to run after the current frame completes and no other
  /// idle task is active. Returns an [IdleTask] handle for cancellation.
  IdleTask runWhenIdle(Future<void> Function() task) {
    final completer = Completer<void>();
    final idleTask = IdleTask._(completer, this);
    final entry = _QueueEntry(task: task, idleTask: idleTask);
    _queue.add(entry);
    if (!_processing) {
      _processNext();
    }
    return idleTask;
  }

  /// Cancels all pending tasks. Tasks already running will complete.
  void cancelAll() {
    while (_queue.isNotEmpty) {
      final _QueueEntry entry = _queue.removeFirst();
      entry.idleTask._cancelled = true;
      if (!entry.idleTask._completer.isCompleted) {
        entry.idleTask._completer.complete();
      }
    }
  }

  void _remove(IdleTask idleTask) {
    _queue.removeWhere((entry) => identical(entry.idleTask, idleTask));
  }

  Future<void> _processNext() async {
    if (_queue.isEmpty) {
      _processing = false;
      return;
    }
    _processing = true;

    final _QueueEntry entry = _queue.removeFirst();
    if (entry.idleTask._cancelled) {
      // Skip cancelled tasks and move to next.
      await _processNext();
      return;
    }

    // Wait for the current frame to finish before executing.
    await _waitForIdle();

    // Re-check cancellation after yielding.
    if (entry.idleTask._cancelled) {
      if (!entry.idleTask._completer.isCompleted) {
        entry.idleTask._completer.complete();
      }
      await _processNext();
      return;
    }

    try {
      await entry.task();
    } catch (e) {
      // Task errors are swallowed — callers should handle their own errors.
    } finally {
      if (!entry.idleTask._completer.isCompleted) {
        entry.idleTask._completer.complete();
      }
      // Process next item in the queue.
      await _processNext();
    }
  }

  /// Waits until the scheduler is idle (post-frame).
  Future<void> _waitForIdle() {
    final completer = Completer<void>();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      completer.complete();
    });
    // Ensure a frame is scheduled so the callback fires.
    SchedulerBinding.instance.ensureVisualUpdate();
    return completer.future;
  }
}

class _QueueEntry extends Equatable {
  const _QueueEntry({required this.task, required this.idleTask});

  final Future<void> Function() task;
  final IdleTask idleTask;

  @override
  List<Object?> get props => [task, idleTask];
}
