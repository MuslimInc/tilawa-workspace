import 'package:dartz_plus/dartz_plus.dart';

import '../entities/quran_session.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/session_repository.dart';

class GetTeacherSessionsUseCase {
  const GetTeacherSessionsUseCase(this._repository);

  final SessionRepository _repository;

  /// Upcoming sessions only — dashboard does not load full history.
  Future<Either<QuranSessionsFailure, List<QuranSession>>> call(
    String teacherId, {
    int limit = kDefaultSessionPageSize,
  }) => _repository.getTeacherUpcomingSessions(teacherId, limit: limit);
}
