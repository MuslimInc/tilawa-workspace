import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fakes/fake_audit_repository.dart';
import '../../helpers/fakes/fake_session_aggregate_repository.dart';
import '../../helpers/fixtures/session_aggregate_fixtures.dart';

void main() {
  late FakeSessionAggregateRepository aggregateRepository;
  late FakeAuditRepository auditRepository;

  setUp(() {
    aggregateRepository = FakeSessionAggregateRepository()
      ..store['booking_1'] = makeAggregate(id: 'booking_1').copyWith(
        sessionId: 'session_1',
      );
    auditRepository = FakeAuditRepository();
  });

  blocTest<SessionDetailBloc, SessionDetailState>(
    'loads session detail when timeline read is denied',
    build: () => SessionDetailBloc(
      aggregateRepository: aggregateRepository,
      getTimeline: GetSessionTimelineUseCase(
        auditRepository..failWith = const UnauthorizedFailure(),
      ),
    ),
    act: (bloc) => bloc.add(
      const SessionDetailLoadRequested(bookingId: 'booking_1'),
    ),
    expect: () => [
      const SessionDetailLoading(),
      isA<SessionDetailSuccess>()
          .having((s) => s.aggregate.id, 'aggregate id', 'booking_1')
          .having((s) => s.timeline, 'timeline', isEmpty),
    ],
  );

  blocTest<SessionDetailBloc, SessionDetailState>(
    'requests timeline by linked session id',
    build: () {
      auditRepository.events.add(
        SessionAuditEvent(
          sessionId: 'session_1',
          actorId: 'student_1',
          actorRole: ActorRole.student,
          action: SessionAction.createDraft,
          source: ActionSource.mobileApp,
          previousStatus: SessionLifecycleStatus.scheduled,
          newStatus: SessionLifecycleStatus.scheduled,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      return SessionDetailBloc(
        aggregateRepository: aggregateRepository,
        getTimeline: GetSessionTimelineUseCase(auditRepository),
      );
    },
    act: (bloc) => bloc.add(
      const SessionDetailLoadRequested(bookingId: 'booking_1'),
    ),
    expect: () => [
      const SessionDetailLoading(),
      isA<SessionDetailSuccess>().having(
        (s) => s.timeline.length,
        'timeline length',
        1,
      ),
    ],
  );
}
