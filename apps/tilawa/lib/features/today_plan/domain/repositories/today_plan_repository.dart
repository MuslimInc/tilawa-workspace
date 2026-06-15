/// Stores Today Plan progress that belongs on device.
abstract class TodayPlanRepository {
  Future<Set<String>> getCompletedTaskIds(String dateKey);

  Future<void> setTaskCompleted({
    required String dateKey,
    required String taskId,
    required bool completed,
  });
}
