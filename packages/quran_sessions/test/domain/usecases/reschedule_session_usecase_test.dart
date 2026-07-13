import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fakes/fake_audit_repository.dart';
import '../../helpers/fakes/fake_session_aggregate_repository.dart';
import '../../helpers/fakes/fake_session_command_gateway.dart';
import '../../helpers/fakes/fake_session_notification_gateway.dart';
import '../../helpers/fixtures/session_aggregate_fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 1, 1, 10);

  group('RequestRescheduleUseCase', () {
    late FakeSessionAggregateRepository repository;
    late RequestRescheduleUseCase useCase;

    setUp(() {
      repository = FakeSessionAggregateRepository()
        ..store['session_1'] = makeAggregate(
          startsAt: now.add(const Duration(hours: 30)),
        );
      useCase = RequestRescheduleUseCase(
        aggregateRepository: repository,
        lifecycleGuard: const SessionLifecycleGuard(),
        reschedulePolicy: ConfigurableReschedulePolicy(now: () => now),
        notificationGateway: FakeSessionNotificationGateway(),
        auditRepository: FakeAuditRepository(),
        now: () => now,
      );
    });

    test('T-R01 allows first reschedule', () async {
      final result = await useCase(
        sessionId: 'session_1',
        actorRole: ActorRole.student,
        actorId: 'student_1',
        reason: 'conflict',
      );
      result.fold(
        (_) => fail('expected Right'),
        (aggregate) {
          check(
            aggregate.lifecycleStatus,
          ).equals(SessionLifecycleStatus.rescheduled);
          check(aggregate.rescheduleCount).equals(1);
        },
      );
    });

    test('T-R02 blocks second reschedule', () async {
      repository.store['session_1'] = makeAggregate(
        startsAt: now.add(const Duration(hours: 30)),
        rescheduleCount: 1,
      );
      final result = await useCase(
        sessionId: 'session_1',
        actorRole: ActorRole.student,
        actorId: 'student_1',
        reason: 'again',
      );
      check(result.isLeft()).isTrue();
    });
  });

  group('ConfirmRescheduleUseCase', () {
    late FakeSessionAggregateRepository repository;
    late FakeSessionCommandGateway commandGateway;
    late ConfirmRescheduleUseCase useCase;

    setUp(() {
      repository = FakeSessionAggregateRepository()
        ..store['session_2'] = makeAggregate(
          id: 'session_2',
          status: SessionLifecycleStatus.rescheduled,
          slotId: 'slot_old',
        );
      commandGateway = FakeSessionCommandGateway();
      useCase = ConfirmRescheduleUseCase(
        aggregateRepository: repository,
        lifecycleGuard: const SessionLifecycleGuard(),
        commandGateway: commandGateway,
        notificationGateway: FakeSessionNotificationGateway(),
        auditRepository: FakeAuditRepository(),
        now: () => now,
      );
    });

    test('T-R04 confirms with available slot and swaps', () async {
      final result = await useCase(
        sessionId: 'session_2',
        actorRole: ActorRole.teacher,
        actorId: 'teacher_1',
        reason: 'ok',
        newSlotId: 'slot_new',
        isTargetSlotAvailable: true,
      );
      check(result.isRight()).isTrue();
      check(commandGateway.calls).contains('swap:slot_old:slot_new');
    });

    test('T-R05 fails when target slot unavailable', () async {
      final result = await useCase(
        sessionId: 'session_2',
        actorRole: ActorRole.teacher,
        actorId: 'teacher_1',
        reason: 'ok',
        newSlotId: 'slot_new',
        isTargetSlotAvailable: false,
      );
      result.fold(
        (failure) => check(failure).isA<SlotUnavailableFailure>(),
        (_) => fail('expected Left'),
      );
    });
  });
}
