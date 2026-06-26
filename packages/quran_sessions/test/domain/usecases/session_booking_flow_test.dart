import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_booked_slot_lock_repository.dart';
import '../../helpers/fakes/fake_session_aggregate_repository.dart';
import '../../helpers/fakes/fake_session_mutation_gateway.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_teacher_profile_repository.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/fixtures/session_aggregate_fixtures.dart';
import '../../helpers/lifecycle_test_helpers.dart';

void main() {
  const studentId = 'student_1';
  const teacherId = 'teacher_1';
  final fixedNow = DateTime.utc(2026, 1, 9);
  final windowFrom = DateTime.utc(2026, 1, 10);
  final windowTo = DateTime.utc(2026, 1, 17);

  late FakeScheduleRepository scheduleRepo;
  late FakeBookedSlotLockRepository lockRepo;
  late FakeSessionRepository sessionRepo;
  late FakeSessionMutationGateway mutationGateway;
  late FakeTeacherProfileRepository teacherProfiles;
  late GetTeacherAvailabilityUseCase getAvailability;
  late SubmitSessionBookingUseCase submitBooking;
  late TeacherAvailability bookableSlot;

  setUpAll(tz_data.initializeTimeZones);

  setUp(() async {
    scheduleRepo = FakeScheduleRepository()..schedule = makeWeeklySchedule();
    lockRepo = FakeBookedSlotLockRepository();
    sessionRepo = FakeSessionRepository();
    mutationGateway = FakeSessionMutationGateway();
    teacherProfiles = FakeTeacherProfileRepository(
      profile: _teacherProfile(
        externalMeetingUrl: 'https://meet.example.com/room',
      ),
    );
    getAvailability = buildGetTeacherAvailabilityUseCase(
      scheduleRepository: scheduleRepo,
      bookedSlotLockRepository: lockRepo,
      now: () => fixedNow,
    );
    submitBooking = _buildSubmitBooking(
      getAvailability: getAvailability,
      mutationGateway: mutationGateway,
      teacherProfiles: teacherProfiles,
      sessionModePolicy: SessionModePolicy.freeBeta,
    );
    mutationGateway.onCreate =
        ({
          required String teacherId,
          required String studentId,
          required String slotId,
        }) async {
          final start = GeneratedSlot.parseStartUtc(
            teacherId: teacherId,
            slotId: slotId,
          );
          if (start == null) {
            return Left(SlotUnavailableFailure(slotId));
          }
          lockRepo.seedHardLock(teacherId: teacherId, startUtc: start);
          final sessionStart = DateTime.now().add(const Duration(days: 2));
          final endsAt = sessionStart.add(const Duration(minutes: 30));
          sessionRepo.sessions.add(
            makeSession(
              id: 'booking_$slotId',
              studentId: studentId,
              teacherId: teacherId,
              startsAt: sessionStart,
              endsAt: endsAt,
            ),
          );
          return Right(
            SessionBookingOutcome(
              aggregate: SessionAggregate(
                id: 'booking_$slotId',
                teacherId: teacherId,
                studentId: studentId,
                slotId: slotId,
                startsAt: start,
                pricingType: SessionPricingType.free,
                lifecycleStatus: SessionLifecycleStatus.scheduled,
                createdAt: fixedNow,
                updatedAt: fixedNow,
              ),
            ),
          );
        };

    final slots = await getAvailability(
      teacherId,
      from: windowFrom,
      to: windowTo,
    );
    bookableSlot = slots.fold(
      (_) => throw StateError('expected slots'),
      (value) => value.first,
    );
  });

  group('Session booking flow', () {
    test('external meeting booking succeeds', () async {
      final result = await submitBooking(
        teacherId: teacherId,
        slotId: bookableSlot.slotId,
        callType: SessionCallType.externalMeeting,
      );

      check(result.isRight()).isTrue();
      check(mutationGateway.calls).length.equals(1);
    });

    test('voice call booking succeeds under free beta policy', () async {
      final result = await submitBooking(
        teacherId: teacherId,
        slotId: bookableSlot.slotId,
        callType: SessionCallType.voiceCall,
      );

      check(result.isRight()).isTrue();
      result.fold(
        (_) => fail('expected Right'),
        (outcome) => check(
          outcome.aggregate.lifecycleStatus,
        ).equals(SessionLifecycleStatus.scheduled),
      );
    });

    test('video call booking succeeds under free beta policy', () async {
      final result = await submitBooking(
        teacherId: teacherId,
        slotId: bookableSlot.slotId,
        callType: SessionCallType.videoCall,
      );

      check(result.isRight()).isTrue();
    });

    test(
      'rejects voice and video when session mode policy is external only',
      () async {
        final externalOnly = _buildSubmitBooking(
          getAvailability: getAvailability,
          mutationGateway: FakeSessionMutationGateway(),
          teacherProfiles: teacherProfiles,
          sessionModePolicy: SessionModePolicy.externalOnly,
        );

        final voice = await externalOnly(
          teacherId: teacherId,
          slotId: bookableSlot.slotId,
          callType: SessionCallType.voiceCall,
        );
        final video = await externalOnly(
          teacherId: teacherId,
          slotId: bookableSlot.slotId,
          callType: SessionCallType.videoCall,
        );

        check(voice.isLeft()).isTrue();
        voice.fold(
          (f) => check(f).isA<UnsupportedSessionModeFailure>(),
          (_) => fail('expected Left'),
        );
        check(video.isLeft()).isTrue();
        video.fold(
          (f) => check(f).isA<UnsupportedSessionModeFailure>(),
          (_) => fail('expected Left'),
        );
      },
    );

    test('rejects booking when student is not authenticated', () async {
      final unauthenticated = SubmitSessionBookingUseCase(
        mutationGateway: mutationGateway,
        getAvailability: getAvailability,
        authSession: _UnauthenticatedAuthSession(),
        teacherProfiles: teacherProfiles,
      );

      final result = await unauthenticated(
        teacherId: teacherId,
        slotId: bookableSlot.slotId,
        callType: SessionCallType.externalMeeting,
      );

      check(result.isLeft()).isTrue();
      result.fold(
        (f) => check(f).isA<UnauthorizedFailure>(),
        (_) => fail('expected Left'),
      );
      check(mutationGateway.calls).isEmpty();
    });

    test('rejects booking when gateway returns server failure', () async {
      mutationGateway.onCreate =
          ({
            required String teacherId,
            required String studentId,
            required String slotId,
          }) async => const Left(ServerFailure(statusCode: 500));

      final result = await submitBooking(
        teacherId: teacherId,
        slotId: bookableSlot.slotId,
        callType: SessionCallType.externalMeeting,
      );

      check(result.isLeft()).isTrue();
      result.fold(
        (f) => check(f).isA<ServerFailure>(),
        (_) => fail('expected Left'),
      );
    });

    test('rejects slot already locked before submit', () async {
      lockRepo.seedHardLock(
        teacherId: teacherId,
        startUtc: bookableSlot.startsAt.toUtc(),
      );

      final result = await submitBooking(
        teacherId: teacherId,
        slotId: bookableSlot.slotId,
        callType: SessionCallType.externalMeeting,
      );

      check(result.isLeft()).isTrue();
      result.fold(
        (f) => check(f).isA<SlotUnavailableFailure>(),
        (_) => fail('expected Left'),
      );
      check(mutationGateway.calls).isEmpty();
    });

    test('prevents double booking on the same slot', () async {
      final first = await submitBooking(
        teacherId: teacherId,
        slotId: bookableSlot.slotId,
        callType: SessionCallType.externalMeeting,
      );
      check(first.isRight()).isTrue();

      final second = await submitBooking(
        teacherId: teacherId,
        slotId: bookableSlot.slotId,
        callType: SessionCallType.externalMeeting,
      );

      check(second.isLeft()).isTrue();
      second.fold(
        (f) => check(f).isA<SlotUnavailableFailure>(),
        (_) => fail('expected Left'),
      );
      check(mutationGateway.calls).length.equals(1);
    });

    test('removes booked slot from teacher availability', () async {
      final before = await getAvailability(
        teacherId,
        from: windowFrom,
        to: windowTo,
      );
      check(
        before.fold(
          (_) => false,
          (slots) => slots.any((s) => s.slotId == bookableSlot.slotId),
        ),
      ).isTrue();

      final booked = await submitBooking(
        teacherId: teacherId,
        slotId: bookableSlot.slotId,
        callType: SessionCallType.voiceCall,
      );
      check(booked.isRight()).isTrue();

      final after = await getAvailability(
        teacherId,
        from: windowFrom,
        to: windowTo,
      );
      check(
        after.fold(
          (_) => false,
          (slots) => slots.any((s) => s.slotId == bookableSlot.slotId),
        ),
      ).isFalse();
    });

    test('successful booking appears in student My Sessions list', () async {
      check(sessionRepo.sessions).isEmpty();

      final result = await submitBooking(
        teacherId: teacherId,
        slotId: bookableSlot.slotId,
        callType: SessionCallType.videoCall,
      );
      check(result.isRight()).isTrue();

      final sessions = await GetStudentSessionsUseCase(sessionRepo)(
        studentId,
      );
      sessions.fold(
        (_) => fail('expected Right'),
        (page) {
          check(page.upcoming).length.equals(1);
          check(
            page.upcoming.first.id,
          ).equals('booking_${bookableSlot.slotId}');
          check(page.upcoming.first.studentId).equals(studentId);
        },
      );
    });
  });

  group('Session cancel after booking', () {
    test('cancel removes session from student upcoming list', () async {
      final booked = await submitBooking(
        teacherId: teacherId,
        slotId: bookableSlot.slotId,
        callType: SessionCallType.externalMeeting,
      );
      final bookingId = booked.fold(
        (_) => throw StateError('expected booking'),
        (outcome) => outcome.aggregate.id,
      );

      final aggregateRepo = FakeSessionAggregateRepository();
      aggregateRepo.store[bookingId] = makeAggregate(
        id: bookingId,
        startsAt: DateTime.now().add(const Duration(days: 2)),
        slotId: bookableSlot.slotId,
        pricingType: SessionPricingType.free,
        paymentReference: null,
      );

      final cancelSession = buildCancelSessionViaServerUseCase(
        repository: aggregateRepo,
      );
      final cancelResult = await cancelSession(
        bookingId: bookingId,
        actorId: studentId,
        reason: 'schedule conflict',
        actorRole: ActorRole.student,
      );
      check(cancelResult.isRight()).equals(true);

      sessionRepo.sessions.removeWhere((s) => s.id == bookingId);

      final sessions = await GetStudentSessionsUseCase(sessionRepo)(studentId);
      sessions.fold(
        (_) => fail('expected Right'),
        (page) => check(page.upcoming).isEmpty(),
      );
    });
  });
}

SubmitSessionBookingUseCase _buildSubmitBooking({
  required GetTeacherAvailabilityUseCase getAvailability,
  required FakeSessionMutationGateway mutationGateway,
  required FakeTeacherProfileRepository teacherProfiles,
  SessionModePolicy sessionModePolicy = SessionModePolicy.freeBeta,
}) {
  return SubmitSessionBookingUseCase(
    mutationGateway: mutationGateway,
    getAvailability: getAvailability,
    authSession: _FakeAuthSession('student_1'),
    teacherProfiles: teacherProfiles,
    sessionModePolicy: sessionModePolicy,
  );
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

class _FakeAuthSession implements AuthSessionProvider {
  _FakeAuthSession(this.userId);
  final String userId;

  @override
  String? get currentUserId => userId;

  @override
  Stream<String?> watchUserId() => Stream.value(userId);
}

class _UnauthenticatedAuthSession implements AuthSessionProvider {
  @override
  String? get currentUserId => null;

  @override
  Stream<String?> watchUserId() => Stream.value(null);
}
