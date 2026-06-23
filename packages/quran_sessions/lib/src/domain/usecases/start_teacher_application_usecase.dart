import 'package:dartz_plus/dartz_plus.dart';

import '../entities/teacher_application.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/teacher_application_repository.dart';

/// Starts a new teacher application in the `draft` state.
///
/// Returns [TeacherApplicationAlreadyPendingFailure] if the user already has
/// a pending or approved application.
class StartTeacherApplicationUseCase {
  const StartTeacherApplicationUseCase(this._repository);

  final TeacherApplicationRepository _repository;

  Future<Either<QuranSessionsFailure, TeacherApplication>> call(
    String userId,
  ) => _repository.createDraft(userId);
}
