import 'package:dartz_plus/dartz_plus.dart';

import '../entities/quran_session.dart';
import '../failures/quran_sessions_failure.dart';
import '../policies/session_list_classifier.dart';
import '../repositories/session_repository.dart';

/// Loads the first page of student session buckets for My Sessions tabs.
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
    final pendingSessions = <QuranSession>[];
    final cancelledSessions = <QuranSession>[];
    final reclassifiedPast = <QuranSession>[];

    for (final session in upcomingPage.sessions) {
      if (SessionListClassifier.isStudentUpcoming(session)) {
        upcomingSessions.add(session);
      } else if (SessionListClassifier.isStudentPending(session)) {
        pendingSessions.add(session);
      } else if (SessionListClassifier.isCancelledSession(session)) {
        cancelledSessions.add(session);
      } else {
        reclassifiedPast.add(session);
      }
    }

    final pastSessions = <QuranSession>[];
    for (final session in pastPage.sessions) {
      if (SessionListClassifier.isCancelledSession(session)) {
        cancelledSessions.add(session);
      } else {
        pastSessions.add(session);
      }
    }

    return Right(
      StudentSessionsPage(
        upcoming: upcomingSessions,
        pending: pendingSessions,
        cancelled: cancelledSessions,
        past: [...reclassifiedPast, ...pastSessions],
        pastNextCursor: pastPage.nextCursor,
      ),
    );
  }
}

/// First-page student sessions split for the My Sessions screen (Q-ST-01).
class StudentSessionsPage {
  const StudentSessionsPage({
    required this.upcoming,
    this.pending = const [],
    this.cancelled = const [],
    required this.past,
    this.pastNextCursor,
  });

  final List<QuranSession> upcoming;
  final List<QuranSession> pending;
  final List<QuranSession> cancelled;
  final List<QuranSession> past;
  final String? pastNextCursor;
}
