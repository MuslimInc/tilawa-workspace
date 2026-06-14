/// The high-level action category for a Today Plan task.
enum TodayPlanTaskKind { reading, listening, adhkar, tasbeeh }

/// Completion state for a Today Plan task.
enum TodayPlanTaskStatus { pending, completed }

/// A single calm daily action in Today Plan.
final class TodayPlanTask {
  const TodayPlanTask({
    required this.id,
    required this.kind,
    required this.minutes,
    this.status = TodayPlanTaskStatus.pending,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final TodayPlanTaskKind kind;
  final int minutes;
  final TodayPlanTaskStatus status;
  final Map<String, Object?> metadata;

  bool get isCompleted => status == TodayPlanTaskStatus.completed;

  TodayPlanTask copyWith({TodayPlanTaskStatus? status}) {
    return TodayPlanTask(
      id: id,
      kind: kind,
      minutes: minutes,
      status: status ?? this.status,
      metadata: metadata,
    );
  }
}

/// User-facing daily plan summary.
final class TodayPlan {
  const TodayPlan({
    required this.dateKey,
    required this.tasks,
    required this.streakDays,
    this.isAdaptive = false,
  });

  final String dateKey;
  final List<TodayPlanTask> tasks;
  final int streakDays;
  final bool isAdaptive;

  int get completedCount => tasks.where((task) => task.isCompleted).length;

  int get totalCount => tasks.length;

  int get minutesRemaining => tasks
      .where((task) => !task.isCompleted)
      .fold<int>(0, (total, task) => total + task.minutes);

  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;

  bool get isCompleted => totalCount > 0 && completedCount == totalCount;

  TodayPlanTask? get nextTask {
    for (final TodayPlanTask task in tasks) {
      if (!task.isCompleted) {
        return task;
      }
    }
    return null;
  }

  TodayPlan copyWithTask(TodayPlanTask updatedTask) {
    return TodayPlan(
      dateKey: dateKey,
      tasks: tasks
          .map((task) => task.id == updatedTask.id ? updatedTask : task)
          .toList(growable: false),
      streakDays: streakDays,
      isAdaptive: isAdaptive,
    );
  }
}
