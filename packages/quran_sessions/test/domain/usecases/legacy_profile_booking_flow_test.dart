import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions/src/data/repositories/schedule_repository_impl.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../helpers/fakes/fake_booked_slot_lock_repository.dart';
import '../../helpers/fakes/fake_session_mutation_gateway.dart';

void main() {
  const profileId = 'a1sYAAaBHg5aq1uwya0o';
  const legacyUserId = 'firebase_uid_teacher';
  final fixedNow = DateTime.utc(2026, 1, 9);
  final windowFrom = DateTime.utc(2026, 1, 10);
  final windowTo = DateTime.utc(2026, 1, 17);

  late FakeSessionMutationGateway mutationGateway;
  late SubmitSessionBookingUseCase submitBooking;
  late TeacherAvailability bookableSlot;

  setUpAll(tz_data.initializeTimeZones);

  setUp(() async {
    mutationGateway = FakeSessionMutationGateway();
    final scheduleRepo = ScheduleRepositoryImpl(
      _LegacyScheduleRemoteDataSource(
        schedulesByTeacherId: {
          legacyUserId: _legacyScheduleDto(legacyUserId),
        },
      ),
      teacherProfiles: _FakeTeacherProfileRepository(
        _teacherProfile(profileId: profileId, userId: legacyUserId),
      ),
    );
    final getAvailability = GetTeacherAvailabilityUseCase(
      scheduleRepository: scheduleRepo,
      bookedSlotLocks: FakeBookedSlotLockRepository(),
      now: () => fixedNow,
    );
    submitBooking = SubmitSessionBookingUseCase(
      mutationGateway: mutationGateway,
      getAvailability: getAvailability,
      authSession: _FakeAuthSession('student_1'),
      teacherProfiles: _FakeTeacherProfileRepository(
        _teacherProfile(profileId: profileId, userId: legacyUserId),
      ),
    );

    final slots = await getAvailability(
      profileId,
      from: windowFrom,
      to: windowTo,
    );
    bookableSlot = slots.fold(
      (_) => throw StateError('expected slots'),
      (value) => value.first,
    );
  });

  test('legacy schedule path emits profile-prefixed slot ids', () {
    check(bookableSlot.slotId.startsWith('${profileId}_')).isTrue();
    check(
      GeneratedSlot.parseStartUtc(
        teacherId: profileId,
        slotId: bookableSlot.slotId,
      ),
    ).isNotNull();
  });

  test(
    'profileId teacher booking succeeds after legacy schedule read',
    () async {
      final result = await submitBooking(
        teacherId: profileId,
        slotId: bookableSlot.slotId,
        callType: SessionCallType.voiceCall,
      );

      check(result.isRight()).isTrue();
      check(mutationGateway.calls).length.equals(1);
      check(
        mutationGateway.calls.single,
      ).equals('create:${bookableSlot.slotId}');
      result.fold(
        (_) => fail('expected Right'),
        (outcome) {
          check(outcome.aggregate.teacherId).equals(profileId);
          check(outcome.aggregate.slotId).equals(bookableSlot.slotId);
        },
      );
    },
  );

  test(
    'legacy userId slot lock blocks profile-prefixed availability',
    () async {
      final lockRepo = BookedSlotLockRepositoryImpl(
        _LegacyLockRemoteDataSource(
          locksByTeacherId: {
            legacyUserId: [
              SlotLockDto(
                slotId: GeneratedSlot.deterministicId(
                  legacyUserId,
                  DateTime.utc(2026, 1, 10, 7, 0),
                ),
                teacherId: legacyUserId,
                lockType: 'hard',
              ),
            ],
          },
        ),
        teacherProfiles: _FakeTeacherProfileRepository(
          _teacherProfile(profileId: profileId, userId: legacyUserId),
        ),
      );
      final getAvailability = GetTeacherAvailabilityUseCase(
        scheduleRepository: ScheduleRepositoryImpl(
          _LegacyScheduleRemoteDataSource(
            schedulesByTeacherId: {
              legacyUserId: _legacyScheduleDto(legacyUserId),
            },
          ),
          teacherProfiles: _FakeTeacherProfileRepository(
            _teacherProfile(profileId: profileId, userId: legacyUserId),
          ),
        ),
        bookedSlotLocks: lockRepo,
        now: () => fixedNow,
      );

      final slots = await getAvailability(
        profileId,
        from: windowFrom,
        to: windowTo,
      );

      slots.fold(
        (_) => fail('expected Right'),
        (value) => check(
          value.any(
            (slot) => slot.startsAt.toUtc() == DateTime.utc(2026, 1, 10, 7, 0),
          ),
        ).isFalse(),
      );
    },
  );
}

WeeklyScheduleDto _legacyScheduleDto(String teacherId) => WeeklyScheduleDto(
  teacherId: teacherId,
  timezone: 'Africa/Cairo',
  slotDurationMinutes: 30,
  minNoticeMinutes: 0,
  maxHorizonDays: 1000,
  bufferBeforeMinutes: 0,
  bufferAfterMinutes: 0,
  weeklyRules: const {
    'sat': [
      {'start': '09:00', 'end': '12:00'},
    ],
  },
  version: 1,
);

TeacherProfile _teacherProfile({
  required String profileId,
  required String userId,
}) => TeacherProfile(
  id: profileId,
  userId: userId,
  displayName: 'Teacher',
  verificationStatus: TeacherVerificationStatus.verified,
  teachingLanguages: const ['ar'],
  specializations: const ['tajweed'],
  averageRating: 0,
  reviewCount: 0,
  isActive: true,
  profileCompleteness: TeacherProfileCompletenessStatus.complete,
  isPubliclyVisible: true,
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

class _FakeTeacherProfileRepository implements TeacherProfileRepository {
  _FakeTeacherProfileRepository(this.profile);
  final TeacherProfile profile;

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> getProfileById(
    String id,
  ) async =>
      id == profile.id ? Right(profile) : const Left(NotFoundFailure(''));

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> createProfile(
    TeacherProfile profile,
  ) async => Right(profile);

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> deactivate(
    String id,
  ) async => const Left(NotFoundFailure(''));

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> getProfileByUserId(
    String userId,
  ) async => const Left(NotFoundFailure(''));

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> reactivate(
    String id,
  ) async => const Left(NotFoundFailure(''));

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> updateProfile(
    TeacherProfile profile,
  ) async => Right(profile);

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> updatePublicProfile(
    TeacherProfile profile,
  ) async => Right(profile);
}

class _LegacyScheduleRemoteDataSource implements ScheduleRemoteDataSource {
  _LegacyScheduleRemoteDataSource({required this.schedulesByTeacherId});

  final Map<String, WeeklyScheduleDto> schedulesByTeacherId;

  @override
  Future<WeeklyScheduleDto?> getSchedule(String teacherId) async =>
      schedulesByTeacherId[teacherId];

  @override
  Future<void> saveSchedule(WeeklyScheduleDto schedule) async {}

  @override
  Future<List<AvailabilityOverrideDto>> getOverrides(
    String teacherId, {
    DateTime? from,
    DateTime? to,
  }) async => const [];

  @override
  Future<AvailabilityOverrideDto?> getOverrideByDate(
    String teacherId,
    String dateKey,
  ) async => null;

  @override
  Future<void> saveOverride(
    String teacherId,
    AvailabilityOverrideDto override,
  ) async {}

  @override
  Future<void> removeOverride(String teacherId, String dateKey) async {}
}

class _LegacyLockRemoteDataSource implements BookedSlotLockRemoteDataSource {
  _LegacyLockRemoteDataSource({required this.locksByTeacherId});

  final Map<String, List<SlotLockDto>> locksByTeacherId;

  @override
  Future<List<SlotLockDto>> getLocksForTeacher(
    String teacherProfileId, {
    required DateTime windowStart,
    required DateTime windowEnd,
  }) async => locksByTeacherId[teacherProfileId] ?? const [];

  @override
  Future<SlotLockDto?> getLockBySlotId(String slotId) async => null;
}
