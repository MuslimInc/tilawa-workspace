import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_booked_slot_lock_repository.dart';
import '../../helpers/fakes/fake_session_mutation_gateway.dart';
import '../../helpers/fakes/fake_teacher_profile_repository.dart';

void main() {
  late FakeScheduleRepository scheduleRepo;
  late FakeBookedSlotLockRepository bookedSlotLockRepo;
  late FakeSessionMutationGateway mutationGateway;
  late FakeTeacherProfileRepository teacherProfiles;
  late SubmitSessionBookingUseCase submitBooking;
  late TeacherAvailability generatedSlot;

  final fixedNow = DateTime.utc(2026, 1, 9);

  setUpAll(tz_data.initializeTimeZones);

  setUp(() async {
    scheduleRepo = FakeScheduleRepository()..schedule = makeWeeklySchedule();
    bookedSlotLockRepo = FakeBookedSlotLockRepository();
    mutationGateway = FakeSessionMutationGateway();
    teacherProfiles = FakeTeacherProfileRepository(
      profile: _teacherProfile(
        externalMeetingUrl: 'https://meet.example.com/room',
      ),
    );
    final getAvailability = buildGetTeacherAvailabilityUseCase(
      scheduleRepository: scheduleRepo,
      bookedSlotLockRepository: bookedSlotLockRepo,
      now: () => fixedNow,
    );
    submitBooking = SubmitSessionBookingUseCase(
      mutationGateway: mutationGateway,
      getAvailability: getAvailability,
      authSession: _FakeAuthSession('student_1'),
      teacherProfiles: teacherProfiles,
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

  test('rejects external booking when teacher has no meeting URL', () async {
    teacherProfiles.seed(
      _teacherProfile(externalMeetingUrl: null),
    );
    submitBooking = SubmitSessionBookingUseCase(
      mutationGateway: mutationGateway,
      getAvailability: buildGetTeacherAvailabilityUseCase(
        scheduleRepository: scheduleRepo,
        bookedSlotLockRepository: bookedSlotLockRepo,
        now: () => fixedNow,
      ),
      authSession: _FakeAuthSession('student_1'),
      teacherProfiles: teacherProfiles,
    );

    final result = await submitBooking(
      teacherId: 'teacher_1',
      slotId: generatedSlot.slotId,
      callType: SessionCallType.externalMeeting,
    );

    check(result.isLeft()).isTrue();
    result.fold(
      (f) => check(f).isA<MeetingLinkUnavailableFailure>(),
      (_) => fail('expected Left'),
    );
    check(mutationGateway.calls.isEmpty).isTrue();
  });

  test('individual external booking succeeds when slot available', () async {
    submitBooking = SubmitSessionBookingUseCase(
      mutationGateway: mutationGateway,
      getAvailability: buildGetTeacherAvailabilityUseCase(
        scheduleRepository: scheduleRepo,
        bookedSlotLockRepository: bookedSlotLockRepo,
        now: () => fixedNow,
      ),
      authSession: _FakeAuthSession('student_1'),
      teacherProfiles: teacherProfiles,
    );

    final result = await submitBooking(
      teacherId: 'teacher_1',
      slotId: generatedSlot.slotId,
      callType: SessionCallType.externalMeeting,
    );

    check(result.isRight()).isTrue();
    check(mutationGateway.calls).length.equals(1);
    result.fold(
      (_) => fail('expected Right'),
      (outcome) => check(
        outcome.aggregate.lifecycleStatus,
      ).equals(SessionLifecycleStatus.scheduled),
    );
  });

  test('rejects booking when slot already taken', () async {
    bookedSlotLockRepo.seedHardLock(
      teacherId: 'teacher_1',
      startUtc: generatedSlot.startsAt.toUtc(),
    );

    final result = await submitBooking(
      teacherId: 'teacher_1',
      slotId: generatedSlot.slotId,
      callType: SessionCallType.externalMeeting,
    );

    check(result.isLeft()).isTrue();
    result.fold(
      (f) => check(f).isA<SlotUnavailableFailure>(),
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

TeacherProfile _teacherProfile({required String? externalMeetingUrl}) =>
    TeacherProfile(
      id: 'teacher_1',
      userId: 'teacher_1',
      displayName: 'Teacher',
      verificationStatus: TeacherVerificationStatus.verified,
      teachingLanguages: const ['ar'],
      specializations: const ['tajweed'],
      averageRating: 0,
      reviewCount: 0,
      isActive: true,
      profileCompleteness: TeacherProfileCompletenessStatus.complete,
      isPubliclyVisible: true,
      externalMeetingUrl: externalMeetingUrl,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
