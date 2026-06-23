/// Persists Friday review banner dismissals until the next Saturday.
abstract interface class FridayReviewReminderStore {
  Future<bool> isDismissed({
    required String teacherId,
    required String nextWeekKey,
  });

  Future<void> dismiss({
    required String teacherId,
    required String nextWeekKey,
    required DateTime until,
  });
}
