import 'package:shared_preferences/shared_preferences.dart';

abstract class TodayPlanLocalDataSource {
  Future<Set<String>> getCompletedTaskIds(String dateKey);

  Future<void> setTaskCompleted({
    required String dateKey,
    required String taskId,
    required bool completed,
  });
}

final class SharedPreferencesTodayPlanLocalDataSource
    implements TodayPlanLocalDataSource {
  SharedPreferencesTodayPlanLocalDataSource(this._prefs);

  final SharedPreferencesAsync _prefs;

  String _completedKey(String dateKey) => 'today_plan.completed.$dateKey';

  @override
  Future<Set<String>> getCompletedTaskIds(String dateKey) async {
    final List<String> ids =
        await _prefs.getStringList(_completedKey(dateKey)) ?? <String>[];
    return ids.toSet();
  }

  @override
  Future<void> setTaskCompleted({
    required String dateKey,
    required String taskId,
    required bool completed,
  }) async {
    final Set<String> ids = await getCompletedTaskIds(dateKey);
    if (completed) {
      ids.add(taskId);
    } else {
      ids.remove(taskId);
    }
    await _prefs.setStringList(_completedKey(dateKey), ids.toList()..sort());
  }
}
