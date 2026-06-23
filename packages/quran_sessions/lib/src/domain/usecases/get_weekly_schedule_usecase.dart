import 'package:dartz_plus/dartz_plus.dart';

import '../entities/weekly_schedule.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/schedule_repository.dart';

/// Loads a teacher's weekly schedule, falling back to an empty template.
class GetWeeklyScheduleUseCase {
  const GetWeeklyScheduleUseCase(this._repository);

  final ScheduleRepository _repository;

  Future<Either<QuranSessionsFailure, WeeklySchedule>> call(
    String teacherId, {
    required String defaultTimezone,
  }) async {
    final result = await _repository.getSchedule(teacherId);
    return result.map(
      (schedule) =>
          (schedule ??
                  WeeklySchedule.empty(
                    teacherId: teacherId,
                    timezone: defaultTimezone,
                  ))
              .detached(),
    );
  }
}
