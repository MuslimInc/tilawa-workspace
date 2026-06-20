import 'package:dartz_plus/dartz_plus.dart';

import '../failures/quran_sessions_failure.dart';
import '../repositories/teacher_repository.dart';

/// Returns a page of verified teachers matching the given filters.
///
/// Business rules (to be filled in during implementation):
/// - Only [TeacherVerificationStatus.verified] teachers are surfaced.
/// - Results are sorted by average rating descending by default.
class GetTeachersUseCase {
  const GetTeachersUseCase(this._repository);

  final TeacherRepository _repository;

  Future<Either<QuranSessionsFailure, TeacherPage>> call({
    String? specialization,
    String? language,
    String? cursor,
  }) => _repository.getTeachers(
    specialization: specialization,
    language: language,
    cursor: cursor,
  );
}
