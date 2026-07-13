import 'package:dartz_plus/dartz_plus.dart';

import '../entities/availability_override.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/schedule_repository.dart';

class SaveAvailabilityOverrideUseCase {
  const SaveAvailabilityOverrideUseCase(this._repository);

  final ScheduleRepository _repository;

  Future<Either<QuranSessionsFailure, void>> call(
    String teacherId,
    AvailabilityOverride override,
  ) {
    return _repository.saveOverride(teacherId, override);
  }
}
