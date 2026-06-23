import 'package:dartz_plus/dartz_plus.dart';

import '../entities/teacher_application.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/teacher_application_repository.dart';

/// Admin use case: rejects a pending [TeacherApplication].
///
/// A rejected applicant may re-apply after the platform cooldown period
/// (default: 30 days). See ADR-003 for the re-application policy.
class RejectTeacherApplicationUseCase {
  const RejectTeacherApplicationUseCase(this._repository);

  final TeacherApplicationRepository _repository;

  Future<Either<QuranSessionsFailure, TeacherApplication>> call({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  }) => _repository.reject(
    applicationId: applicationId,
    reviewedBy: reviewedBy,
    reason: reason,
  );
}
