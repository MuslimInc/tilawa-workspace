import 'package:dartz_plus/dartz_plus.dart';

import '../entities/teacher_application_access.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/teacher_application_access_repository.dart';

/// Resolves whether [userId] may see teacher-application entry points.
class ResolveTeacherApplicationAccessUseCase {
  const ResolveTeacherApplicationAccessUseCase(this._repository);

  final TeacherApplicationAccessRepository _repository;

  Future<Either<QuranSessionsFailure, TeacherApplicationAccess>> call(
    String userId,
  ) {
    return _repository.resolveForUser(userId);
  }
}
