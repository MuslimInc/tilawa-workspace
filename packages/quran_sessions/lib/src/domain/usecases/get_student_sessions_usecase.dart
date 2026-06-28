import 'package:dartz_plus/dartz_plus.dart';

import '../entities/quran_session.dart';
import '../failures/quran_sessions_failure.dart';
import '../policies/session_list_classifier.dart';
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

    final upcomingPage = upcomingResult.fold(
      (_) => throw StateError('unreachable'),
      (page) => page,
    );
    final pastPage = pastResult.fold(
      (_) => throw StateError('unreachable'),
      (page) => page,
    );

    final upcomingSessions = <QuranSession>[];
    final reclassifiedPast = <QuranSession>[];
    for (final session in upcomingPage.sessions) {
      if (SessionListClassifier.isStudentUpcoming(session)) {
        upcomingSessions.add(session);
      } else if (SessionListClassifier.isCancelledSession(session)) {
        upcomingSessions.add(session);
      } else {
        reclassifiedPast.add(session);
      }
    }

    return Right(
      StudentSessionsPage(
        upcoming: upcomingSessions,
        past: [...reclassifiedPast, ...pastPage.sessions],
        pastNextCursor: pastPage.nextCursor,
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
