import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fakes/fake_audit_repository.dart';
import '../../helpers/fakes/fake_compensation_gateway.dart';
import '../../helpers/fakes/fake_session_aggregate_repository.dart';
import '../../helpers/fakes/fake_session_notification_gateway.dart';
import '../../helpers/fixtures/session_aggregate_fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 1, 1, 10);

  group('IssueCompensationUseCase', () {
    late FakeSessionAggregateRepository repository;
    late FakeCompensationGateway compensationGateway;
    late IssueCompensationUseCase useCase;

    setUp(() {
      repository = FakeSessionAggregateRepository()
        ..store['session_1'] = makeAggregate(
          status: SessionLifecycleStatus.cancelledByTeacher,
          pricingType: SessionPricingType.fixedPerSession,
        );
      compensationGateway = FakeCompensationGateway();
      useCase = IssueCompensationUseCase(
        aggregateRepository: repository,
        lifecycleGuard: const SessionLifecycleGuard(),
        compensationPolicy: const ConfigurableCompensationPolicy(),
        compensationGateway: compensationGateway,
        notificationGateway: FakeSessionNotificationGateway(),
        auditRepository: FakeAuditRepository(),
        now: () => now,
      );
    });

    test('issues compensation and moves to compensated', () async {
      final result = await useCase(
        sessionId: 'session_1',
        actorRole: ActorRole.admin,
        actorId: 'admin_1',
        reason: 'teacher cancelled',
      );

      result.fold(
        (_) => fail('expected Right'),
        (value) {
          check(value.aggregate.lifecycleStatus).equals(
            SessionLifecycleStatus.compensated,
          );
          check(value.record.actions).isNotEmpty();
        },
      );
    });

    test('propagates gateway failure', () async {
      compensationGateway.failWith = const TimeoutFailure();
      final result = await useCase(
        sessionId: 'session_1',
        actorRole: ActorRole.admin,
        actorId: 'admin_1',
        reason: 'teacher cancelled',
      );
      result.fold(
        (failure) => check(failure).isA<TimeoutFailure>(),
        (_) => fail('expected Left'),
      );
    });
  });
}
