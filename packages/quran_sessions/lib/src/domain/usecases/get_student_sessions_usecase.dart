import 'package:dartz_plus/dartz_plus.dart';

import '../entities/quran_session.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/session_repository.dart';

/// Loads the first page of upcoming and past student sessions.
class GetStudentSessionsUseCase {
  const GetStudentSessionsUseCase(this._repository);

  final SessionRepository _repository;

  Future<Either<QuranSessionsFailure, StudentSessionsPage>> call(
    String studentId, {
    String? pastCursor,
    int limit = kDefaultSessionPageSize,
  }) async {
    final upcomingResult = await _repository.getStudentUpcomingSessions(
      studentId,
      limit: limit,
    );
    if (upcomingResult.isLeft()) {
      return upcomingResult.map((_) => throw StateError('unreachable'));
    }

    final pastResult = await _repository.getStudentPastSessions(
      studentId,
      cursor: pastCursor,
      limit: limit,
    );
    if (pastResult.isLeft()) {
      return pastResult.map((_) => throw StateError('unreachable'));
    }

    final upcoming = upcomingResult.fold(
      (_) => throw StateError('unreachable'),
      (page) => page,
    );
    final past = pastResult.fold(
      (_) => throw StateError('unreachable'),
      (page) => page,
    );

    return Right(
      StudentSessionsPage(
        upcoming: upcoming.sessions,
        past: past.sessions,
        pastNextCursor: past.nextCursor,
      ),
    );
  }
}

/// First-page student sessions split for the My Sessions screen.
class StudentSessionsPage {
  const StudentSessionsPage({
    required this.upcoming,
    required this.past,
    this.pastNextCursor,
  });

  final List<QuranSession> upcoming;
  final List<QuranSession> past;
  final String? pastNextCursor;
}
