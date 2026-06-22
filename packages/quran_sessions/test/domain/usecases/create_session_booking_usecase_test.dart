import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fakes/fake_audit_repository.dart';
import '../../helpers/fakes/fake_session_aggregate_repository.dart';
import '../../helpers/fakes/fake_session_command_gateway.dart';
import '../../helpers/fakes/fake_session_notification_gateway.dart';

void main() {
  group('CreateSessionBookingUseCase', () {
    late FakeSessionAggregateRepository repository;
    late FakeSessionCommandGateway commandGateway;
    late FakeSessionNotificationGateway notificationGateway;
    late FakeAuditRepository auditRepository;
    late CreateSessionBookingUseCase useCase;
    final now = DateTime.utc(2026, 1, 1, 10);

    setUp(() {
      repository = FakeSessionAggregateRepository();
      commandGateway = FakeSessionCommandGateway();
      notificationGateway = FakeSessionNotificationGateway();
      auditRepository = FakeAuditRepository();
      useCase = CreateSessionBookingUseCase(
        aggregateRepository: repository,
        lifecycleGuard: SessionLifecycleGuard(),
        bookingIntegrityValidator: const BookingIntegrityValidator(),
        commandGateway: commandGateway,
        notificationGateway: notificationGateway,
        auditRepository: auditRepository,
        now: () => now,
      );
    });

    BookingIntegritySnapshot snapshot() => BookingIntegritySnapshot(
      slotAvailable: true,
      teacherActive: true,
      studentActive: true,
      marketEnabled: true,
      startsAt: now.add(const Duration(days: 1)),
      minNotice: const Duration(hours: 1),
      maxAdvanceHorizon: const Duration(days: 30),
      now: () => now,
    );

    test('creates free booking directly to scheduled', () async {
      final result = await useCase(
        sessionId: 's1',
        teacherId: 't1',
        studentId: 'u1',
        slotId: 'slot1',
        startsAt: now.add(const Duration(days: 1)),
        pricingType: SessionPricingType.free,
        integritySnapshot: snapshot(),
      );

      result.fold(
        (_) => fail('expected Right'),
        (aggregate) => check(aggregate.lifecycleStatus).equals(
          SessionLifecycleStatus.scheduled,
        ),
      );
      check(commandGateway.calls).contains('lock:slot1');
    });

    test('paid booking captures payment then schedules', () async {
      final result = await useCase(
        sessionId: 's2',
        teacherId: 't1',
        studentId: 'u1',
        slotId: 'slot2',
        startsAt: now.add(const Duration(days: 1)),
        pricingType: SessionPricingType.fixedPerSession,
        paymentReference: 'pay_123',
        integritySnapshot: snapshot(),
      );

      check(result.isRight()).isTrue();
      check(commandGateway.calls).contains('hold:slot2');
      check(commandGateway.calls).contains('capture:s2');
      check(commandGateway.calls).contains('lock:slot2');
    });

    test('fails when integrity validator rejects slot', () async {
      final result = await useCase(
        sessionId: 's3',
        teacherId: 't1',
        studentId: 'u1',
        slotId: 'slot3',
        startsAt: now.add(const Duration(days: 1)),
        pricingType: SessionPricingType.fixedPerSession,
        paymentReference: 'pay_123',
        integritySnapshot: BookingIntegritySnapshot(
          slotAvailable: false,
          teacherActive: true,
          studentActive: true,
          marketEnabled: true,
          startsAt: now.add(const Duration(days: 1)),
          minNotice: const Duration(hours: 1),
          maxAdvanceHorizon: const Duration(days: 30),
          now: () => now,
        ),
      );

      check(result.isLeft()).isTrue();
      check(commandGateway.calls).isEmpty();
    });
  });
}
