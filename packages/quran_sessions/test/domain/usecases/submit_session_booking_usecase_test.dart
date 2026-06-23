import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_session_mutation_gateway.dart';

void main() {
  late FakeScheduleRepository scheduleRepo;
  late FakeSessionRepository sessionRepo;
  late FakeSessionMutationGateway mutationGateway;
  late SubmitSessionBookingUseCase submitBooking;
  late TeacherAvailability generatedSlot;

  final fixedNow = DateTime.utc(2026, 1, 9);

  setUpAll(tz_data.initializeTimeZones);

  setUp(() async {
    scheduleRepo = FakeScheduleRepository()..schedule = makeWeeklySchedule();
    sessionRepo = FakeSessionRepository();
    mutationGateway = FakeSessionMutationGateway();
    final getAvailability = buildGetTeacherAvailabilityUseCase(
      scheduleRepository: scheduleRepo,
      sessionRepository: sessionRepo,
      now: () => fixedNow,
    );
    submitBooking = SubmitSessionBookingUseCase(
      mutationGateway: mutationGateway,
      getAvailability: getAvailability,
      authSession: _FakeAuthSession('student_1'),
      sessionModePolicy: SessionModePolicy.externalOnly,
    );

    final slots = await getAvailability(
      'teacher_1',
      from: DateTime.utc(2026, 1, 10),
      to: DateTime.utc(2026, 1, 17),
    );
    generatedSlot = slots.fold(
      (_) => throw StateError('no slots'),
      (v) => v.first,
    );
  });

  test('rejects disabled session mode before gateway call', () async {
    final result = await submitBooking(
      teacherId: 'teacher_1',
      slotId: generatedSlot.slotId,
      callType: SessionCallType.voiceCall,
    );

    check(result.isLeft()).isTrue();
    result.fold(
      (f) => check(f).isA<UnsupportedSessionModeFailure>(),
      (_) => fail('expected Left'),
    );
    check(mutationGateway.calls.isEmpty).isTrue();
  });
}

class _FakeAuthSession implements AuthSessionProvider {
  _FakeAuthSession(this.userId);
  final String userId;

  @override
  String? get currentUserId => userId;

  @override
  Stream<String?> watchUserId() => Stream.value(userId);
}
