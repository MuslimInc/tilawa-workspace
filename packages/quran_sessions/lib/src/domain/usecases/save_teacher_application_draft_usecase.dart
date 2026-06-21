import 'package:dartz_plus/dartz_plus.dart';

import '../entities/teacher_application.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/teacher_application_repository.dart';

/// Persists an in-progress draft without advancing its status.
///
/// Returns [TeacherApplicationNotFoundFailure] if no draft exists for the user.
class SaveTeacherApplicationDraftUseCase {
  const SaveTeacherApplicationDraftUseCase(this._repository);

  final TeacherApplicationRepository _repository;

  Future<Either<QuranSessionsFailure, TeacherApplication>> call(
    TeacherApplication draft,
  ) async {
    if (!draft.isDraft) {
      return Left(
        const TeacherApplicationIncompleteFailure(
          reason: 'Only draft applications can be saved via this use case.',
        ),
      );
    }
    return _repository.saveDraft(draft);
  }
}
