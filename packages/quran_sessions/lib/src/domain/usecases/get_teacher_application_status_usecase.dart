import 'package:dartz_plus/dartz_plus.dart';

import '../entities/teacher_application.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/teacher_application_repository.dart';

/// Returns the current [TeacherApplication] for a user.
///
/// Returns [TeacherApplicationNotFoundFailure] if the user has never started
/// an application. The caller should treat that as [TeacherApplicationStatus.none].
class GetTeacherApplicationStatusUseCase {
  const GetTeacherApplicationStatusUseCase(this._repository);

  final TeacherApplicationRepository _repository;

  Future<Either<QuranSessionsFailure, TeacherApplication>> call(
    String userId,
  ) => _repository.getApplication(userId);
}
