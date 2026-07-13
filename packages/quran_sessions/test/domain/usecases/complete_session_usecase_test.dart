import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fakes/fake_audit_repository.dart';
import '../../helpers/fakes/fake_session_aggregate_repository.dart';
import '../../helpers/fixtures/session_aggregate_fixtures.dart';

void main() {
  test('CompleteSessionUseCase marks inProgress as completed', () async {
    final now = DateTime.utc(2026, 1, 1, 10);
    final repository = FakeSessionAggregateRepository()
      ..store['session_1'] = makeAggregate(
        status: SessionLifecycleStatus.inProgress,
      );
    final useCase = CompleteSessionUseCase(
      aggregateRepository: repository,
      lifecycleGuard: const SessionLifecycleGuard(),
      auditRepository: FakeAuditRepository(),
      now: () => now,
    );

    final result = await useCase(
      sessionId: 'session_1',
      actorRole: ActorRole.system,
      actorId: 'system',
    );
    result.fold(
      (_) => fail('expected Right'),
      (aggregate) => check(aggregate.lifecycleStatus).equals(
        SessionLifecycleStatus.completed,
      ),
    );
  });
}
