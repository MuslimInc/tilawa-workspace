import 'package:dartz_plus/dartz_plus.dart';

import '../entities/teacher_availability.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/teacher_repository.dart';

class GetTeacherAvailabilityUseCase {
  const GetTeacherAvailabilityUseCase(this._repository);

  final TeacherRepository _repository;

  Future<Either<QuranSessionsFailure, List<TeacherAvailability>>> call(
    String teacherId, {
    required DateTime from,
    required DateTime to,
  }) => _repository.getAvailableSlots(teacherId, from: from, to: to);
}
