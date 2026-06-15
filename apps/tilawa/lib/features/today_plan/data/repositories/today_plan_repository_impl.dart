import '../../domain/repositories/today_plan_repository.dart';
import '../datasources/today_plan_local_datasource.dart';

final class TodayPlanRepositoryImpl implements TodayPlanRepository {
  const TodayPlanRepositoryImpl(this._localDataSource);

  final TodayPlanLocalDataSource _localDataSource;

  @override
  Future<Set<String>> getCompletedTaskIds(String dateKey) {
    return _localDataSource.getCompletedTaskIds(dateKey);
  }

  @override
  Future<void> setTaskCompleted({
    required String dateKey,
    required String taskId,
    required bool completed,
  }) {
    return _localDataSource.setTaskCompleted(
      dateKey: dateKey,
      taskId: taskId,
      completed: completed,
    );
  }
}
