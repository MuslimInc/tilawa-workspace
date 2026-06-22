import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fakes/fake_audit_repository.dart';
import '../../helpers/fakes/fake_session_aggregate_repository.dart';
import '../../helpers/fakes/fake_session_command_gateway.dart';
import '../../helpers/fakes/fake_session_notification_gateway.dart';
import '../../helpers/fixtures/session_aggregate_fixtures.dart';

void main() {
  group('CancelSessionUseCase', () {
    late FakeSessionAggregateRepository repository;
    late FakeSessionCommandGateway commandGateway;
    late FakeSessionNotificationGateway notificationGateway;
    late FakeAuditRepository auditRepository;
    late CancelSessionUseCase useCase;
    final now = DateTime.utc(2026, 1, 1, 10);

    setUp(() {
      repository = FakeSessionAggregateRepository()
        ..store['session_1'] = makeAggregate(
          startsAt: now.add(const Duration(hours: 48)),
        );
      commandGateway = FakeSessionCommandGateway();
      notificationGateway = FakeSessionNotificationGateway();
      auditRepository = FakeAuditRepository();
      useCase = CancelSessionUseCase(
        aggregateRepository: repository,
        lifecycleGuard: SessionLifecycleGuard(now: () => now),
        cancellationPolicy: ConfigurableCancellationPolicy(now: () => now),
        commandGateway: commandGateway,
        notificationGateway: notificationGateway,
        auditRepository: auditRepository,
        now: () => now,
      );
    });

    test('student early cancel refunds paid session', () async {
      final result = await useCase(
        sessionId: 'session_1',
        actorRole: ActorRole.student,
        actorId: 'student_1',
        reason: 'plans changed',
      );

      result.fold(
        (_) => fail('expected Right'),
        (aggregate) => check(aggregate.lifecycleStatus).equals(
          SessionLifecycleStatus.cancelledByStudent,
        ),
      );
      check(
        commandGateway.calls.any((call) => call.startsWith('refund:')),
      ).isTrue();
    });

    test('teacher cancel transitions to cancelledByTeacher', () async {
      final result = await useCase(
        sessionId: 'session_1',
        actorRole: ActorRole.teacher,
        actorId: 'teacher_1',
        reason: 'emergency',
      );
      result.fold(
        (_) => fail('expected Right'),
        (aggregate) => check(aggregate.lifecycleStatus).equals(
          SessionLifecycleStatus.cancelledByTeacher,
        ),
      );
    });

    test('student late cancel blocked by policy', () async {
      repository.store['session_1'] = makeAggregate(
        startsAt: now.add(const Duration(minutes: 30)),
      );
      final result = await useCase(
        sessionId: 'session_1',
        actorRole: ActorRole.student,
        actorId: 'student_1',
        reason: 'late',
      );
      check(result.isLeft()).isTrue();
    });
  });
}
