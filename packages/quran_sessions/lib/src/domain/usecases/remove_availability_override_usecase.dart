import 'package:dartz_plus/dartz_plus.dart';

import '../failures/quran_sessions_failure.dart';
import '../repositories/schedule_repository.dart';

class RemoveAvailabilityOverrideUseCase {
  const RemoveAvailabilityOverrideUseCase(this._repository);

  final ScheduleRepository _repository;

  Future<Either<QuranSessionsFailure, void>> call(
    String teacherId,
    String dateKey,
  ) {
    return _repository.removeOverride(teacherId, dateKey);
  }
}
