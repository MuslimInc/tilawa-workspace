import 'package:dartz_plus/dartz_plus.dart';

import '../entities/teacher_application.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/teacher_application_repository.dart';

/// Advances a draft application to `pending`, triggering admin review.
///
/// Enforces all submission preconditions:
/// - Phone number present and in E.164 format.
/// - At least one teaching language selected.
/// - At least one specialization selected.
/// - Bio is non-empty.
class SubmitTeacherApplicationUseCase {
  const SubmitTeacherApplicationUseCase(this._repository);

  final TeacherApplicationRepository _repository;

  Future<Either<QuranSessionsFailure, TeacherApplication>> call(
    TeacherApplication application,
  ) async {
    if (!application.isDraft) {
      if (application.isPending) {
        return const Left(TeacherApplicationAlreadyPendingFailure());
      }
      return const Left(
        TeacherApplicationIncompleteFailure(
          reason: 'Only draft applications can be submitted.',
        ),
      );
    }

    if (application.phoneNumber == null ||
        application.phoneNumber!.trim().isEmpty) {
      return const Left(TeacherPhoneNumberRequiredFailure());
    }

    if (!application.hasValidPhone) {
      return const Left(InvalidTeacherPhoneNumberFailure());
    }

    final missing = application.missingSubmissionFields;
    if (missing.isNotEmpty) {
      return Left(
        TeacherApplicationIncompleteFailure(
          reason: 'Missing fields: ${missing.join(', ')}',
        ),
      );
    }

    return _repository.submit(application);
  }
}
