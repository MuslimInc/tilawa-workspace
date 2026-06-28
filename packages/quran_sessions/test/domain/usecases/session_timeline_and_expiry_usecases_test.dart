import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fakes/fake_audit_repository.dart';
import '../../helpers/fakes/fake_session_aggregate_repository.dart';
import '../../helpers/fakes/fake_session_command_gateway.dart';
import '../../helpers/fixtures/session_aggregate_fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 1, 1, 10);

  group('GetSessionTimelineUseCase', () {
    test('returns events keyed by linked session doc id', () async {
      final audit = FakeAuditRepository()
        ..events.add(
          SessionAuditEvent(
            sessionId: 'session_doc_1',
            actorId: 'student_1',
            actorRole: ActorRole.student,
            action: SessionAction.createDraft,
            source: ActionSource.mobileApp,
            previousStatus: SessionLifecycleStatus.draft,
            newStatus: SessionLifecycleStatus.draft,
            createdAt: now,
          ),
        );
      final useCase = GetSessionTimelineUseCase(audit);
      final result = await useCase(
        bookingId: 'booking_1',
        sessionId: 'session_doc_1',
      );
      result.fold(
        (_) => fail('expected Right'),
        (events) => check(events.length).equals(1),
      );
    });

    test('returns events from audit repository', () async {
      final audit = FakeAuditRepository()
        ..events.add(
          SessionAuditEvent(
            sessionId: 'session_1',
            actorId: 'student_1',
            actorRole: ActorRole.student,
            action: SessionAction.createDraft,
            source: ActionSource.mobileApp,
            previousStatus: SessionLifecycleStatus.draft,
            newStatus: SessionLifecycleStatus.draft,
            createdAt: now,
          ),
        );
      final useCase = GetSessionTimelineUseCase(audit);
      final result = await useCase(bookingId: 'session_1');
      result.fold(
        (_) => fail('expected Right'),
        (events) => check(events.length).equals(1),
      );
    });
  });

  group('ExpirePendingReservationsUseCase', () {
    test('expires pending rows and releases slot', () async {
      final repo = FakeSessionAggregateRepository()
        ..store['session_1'] = makeAggregate(
          status: SessionLifecycleStatus.pendingPayment,
          startsAt: now.add(const Duration(minutes: 5)),
        );
      final command = FakeSessionCommandGateway();
      final audit = FakeAuditRepository();
      final useCase = ExpirePendingReservationsUseCase(
        aggregateRepository: repo,
        lifecycleGuard: SessionLifecycleGuard(),
        commandGateway: command,
        auditRepository: audit,
        now: () => now,
      );

      final result = await useCase();
      result.fold(
        (_) => fail('expected Right'),
        (rows) {
          check(rows.length).equals(1);
          check(
            rows.single.lifecycleStatus,
          ).equals(SessionLifecycleStatus.expired);
        },
      );
      check(command.calls).contains('release:slot_1');
    });
  });
}
