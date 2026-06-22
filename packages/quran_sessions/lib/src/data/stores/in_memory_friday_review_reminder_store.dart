import '../../boundaries/scheduling/friday_review_reminder_store.dart';

/// In-memory dismiss store for tests and MVP backends.
class InMemoryFridayReviewReminderStore implements FridayReviewReminderStore {
  final _dismissedUntil = <String, DateTime>{};

  String _key(String teacherId, String nextWeekKey) =>
      '$teacherId|$nextWeekKey';

  @override
  Future<bool> isDismissed({
    required String teacherId,
    required String nextWeekKey,
  }) async {
    final until = _dismissedUntil[_key(teacherId, nextWeekKey)];
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  @override
  Future<void> dismiss({
    required String teacherId,
    required String nextWeekKey,
    required DateTime until,
  }) async {
    _dismissedUntil[_key(teacherId, nextWeekKey)] = until;
  }
}
