import 'package:dartz_plus/dartz_plus.dart';

import '../entities/quran_session.dart';
import '../repositories/session_repository.dart';
import '../failures/quran_sessions_failure.dart';

class GetStudentSessionsUseCase {
  const GetStudentSessionsUseCase(this._repository);

  final SessionRepository _repository;

  Future<Either<QuranSessionsFailure, List<QuranSession>>> call(
    String studentId,
  ) => _repository.getStudentSessions(studentId);
}
