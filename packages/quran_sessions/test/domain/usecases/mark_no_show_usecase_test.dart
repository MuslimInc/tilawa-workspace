import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fakes/fake_audit_repository.dart';
import '../../helpers/fakes/fake_session_aggregate_repository.dart';
import '../../helpers/fakes/fake_session_notification_gateway.dart';
import '../../helpers/fixtures/session_aggregate_fixtures.dart';

void main() {
  final startsAt = DateTime.utc(2026, 1, 1, 10);

  group('MarkNoShowUseCase', () {
    late FakeSessionAggregateRepository repository;
    late MarkNoShowUseCase useCase;

    setUp(() {
      repository = FakeSessionAggregateRepository()
        ..store['session_1'] = makeAggregate(
          startsAt: startsAt,
          status: SessionLifecycleStatus.scheduled,
        );
      useCase = MarkNoShowUseCase(
        aggregateRepository: repository,
        lifecycleGuard: SessionLifecycleGuard(),
        noShowPolicy: NoShowPolicy(
          now: () => startsAt.add(const Duration(minutes: 20)),
        ),
        notificationGateway: FakeSessionNotificationGateway(),
        auditRepository: FakeAuditRepository(),
        now: () => startsAt.add(const Duration(minutes: 20)),
      );
    });

    test('T-N01 teacher absent -> teacherNoShow', () async {
      final result = await useCase(
        sessionId: 'session_1',
        actorRole: ActorRole.admin,
        actorId: 'admin_1',
        teacherJoined: false,
        studentJoined: true,
      );
      result.fold(
        (_) => fail('expected Right'),
        (aggregate) => check(aggregate.lifecycleStatus).equals(
          SessionLifecycleStatus.teacherNoShow,
        ),
      );
    });

    test('T-N02 student absent -> studentNoShow', () async {
      final result = await useCase(
        sessionId: 'session_1',
        actorRole: ActorRole.teacher,
        actorId: 'teacher_1',
        teacherJoined: true,
        studentJoined: false,
      );
      result.fold(
        (_) => fail('expected Right'),
        (aggregate) => check(aggregate.lifecycleStatus).equals(
          SessionLifecycleStatus.studentNoShow,
        ),
      );
    });
  });
}
