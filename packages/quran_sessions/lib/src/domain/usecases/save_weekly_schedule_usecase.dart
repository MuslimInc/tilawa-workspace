import 'package:dartz_plus/dartz_plus.dart';

import '../entities/weekly_schedule.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/schedule_repository.dart';
import '../services/weekly_schedule_validator.dart';

/// Validates, persists, and reloads a teacher's weekly schedule.
class SaveWeeklyScheduleUseCase {
  const SaveWeeklyScheduleUseCase(this._repository, this._validator);

  final ScheduleRepository _repository;
  final WeeklyScheduleValidator _validator;

  Future<Either<QuranSessionsFailure, WeeklySchedule>> call({
    required WeeklySchedule draft,
    required WeeklySchedule baseline,
  }) async {
    final validationFailure = _validator.validate(draft);
    if (validationFailure != null) {
      return Left(validationFailure);
    }

    final toSave = draft.copyWith(
      version: baseline.version + 1,
      updatedAt: DateTime.now(),
    );

    final saveResult = await _repository.saveSchedule(toSave);
    if (saveResult.isLeft()) {
      return saveResult.map((_) => throw StateError('unreachable'));
    }

    final reloadResult = await _repository.getSchedule(toSave.teacherId);
    return reloadResult.map((synced) => synced ?? toSave);
  }
}
