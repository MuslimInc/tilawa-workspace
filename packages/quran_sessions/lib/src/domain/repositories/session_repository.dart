import 'package:dartz_plus/dartz_plus.dart';

import '../entities/quran_session.dart';
import '../failures/quran_sessions_failure.dart';

abstract interface class SessionRepository {
  Future<Either<QuranSessionsFailure, QuranSession>> getSessionById(
    String sessionId,
  );

  Future<Either<QuranSessionsFailure, List<QuranSession>>> getStudentSessions(
    String studentId,
  );

  Future<Either<QuranSessionsFailure, List<QuranSession>>> getTeacherSessions(
    String teacherId,
  );

  /// Updates session notes (student or teacher).
  Future<Either<QuranSessionsFailure, QuranSession>> updateNotes(
    String sessionId, {
    required String notes,
  });
}
