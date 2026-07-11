import 'package:dartz_plus/dartz_plus.dart';

import '../entities/availability_override.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/schedule_repository.dart';

class GetAvailabilityOverridesUseCase {
  const GetAvailabilityOverridesUseCase(this._repository);

  final ScheduleRepository _repository;

  Future<Either<QuranSessionsFailure, List<AvailabilityOverride>>> call(
    String teacherId,
  ) {
    return _repository.getOverrides(teacherId);
  }
}
