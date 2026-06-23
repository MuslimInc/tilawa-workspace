import 'package:checks/checks.dart';
import 'package:quran_sessions/src/data/datasources/schedule_remote_data_source.dart';
import 'package:quran_sessions/src/data/dtos/availability_override_dto.dart';
import 'package:quran_sessions/src/data/dtos/weekly_schedule_dto.dart';
import 'package:quran_sessions/src/data/exceptions/remote_exception.dart';
import 'package:quran_sessions/src/data/mappers/schedule_mapper.dart';
import 'package:quran_sessions/src/data/repositories/schedule_repository_impl.dart';
import 'package:quran_sessions/src/domain/entities/teacher_profile.dart';
import 'package:quran_sessions/src/domain/entities/teacher_verification_status.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/repositories/teacher_profile_repository.dart';
import 'package:quran_sessions/src/domain/rules/teacher_profile_completeness.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:test/test.dart';

class _FakeScheduleRemoteDataSource implements ScheduleRemoteDataSource {
  final schedulesByTeacherId = <String, WeeklyScheduleDto>{};

  Object? throwOnSave;

  @override
  Future<WeeklyScheduleDto?> getSchedule(String teacherId) async =>
      schedulesByTeacherId[teacherId];

  @override
  Future<void> saveSchedule(WeeklyScheduleDto schedule) async {
    if (throwOnSave != null) throw throwOnSave!;
    schedulesByTeacherId[schedule.teacherId] = schedule;
  }

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

WeeklyScheduleDto _sampleSchedule(String teacherId) => WeeklyScheduleDto(
  teacherId: teacherId,
  timezone: 'Africa/Cairo',
  slotDurationMinutes: 30,
  minNoticeMinutes: 120,
  maxHorizonDays: 30,
  bufferBeforeMinutes: 0,
  bufferAfterMinutes: 0,
  weeklyRules: const {
    'sat': [
      {'start': '09:00', 'end': '17:00'},
    ],
  },
  version: 1,
);

TeacherProfile _sampleProfile({
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

void main() {
  group('ScheduleRepositoryImpl', () {
    test('saveSchedule persists through remote datasource', () async {
      final remote = _FakeScheduleRemoteDataSource();
      final repo = ScheduleRepositoryImpl(remote);
      final dto = _sampleSchedule('teacher_1');

      final result = await repo.saveSchedule(dto.toDomain());

      check(result.isRight()).isTrue();
      check(
        remote.schedulesByTeacherId['teacher_1']?.teacherId,
      ).equals('teacher_1');
    });

    test('getSchedule falls back to legacy owner user id path', () async {
      const profileId = 'application_abc';
      const userId = 'firebase_uid_xyz';
      final remote = _FakeScheduleRemoteDataSource()
        ..schedulesByTeacherId[userId] = _sampleSchedule(userId);
      final repo = ScheduleRepositoryImpl(
        remote,
        teacherProfiles: _FakeTeacherProfileRepository(
          _sampleProfile(profileId: profileId, userId: userId),
        ),
      );

      final result = await repo.getSchedule(profileId);

      check(result.isRight()).isTrue();
      result.fold(
        (_) => fail('expected Right'),
        (schedule) {
          check(schedule).isNotNull();
          check(schedule!.isEmpty).isFalse();
        },
      );
    });

    test('saveSchedule maps remote exceptions to failures', () async {
      final remote = _FakeScheduleRemoteDataSource()
        ..throwOnSave = const NetworkException();
      final repo = ScheduleRepositoryImpl(remote);
      final dto = _sampleSchedule('teacher_1');

      final result = await repo.saveSchedule(dto.toDomain());

      check(result.isLeft()).isTrue();
      result.fold(
        (failure) => check(failure).isA<NetworkFailure>(),
        (_) => fail('expected Left'),
      );
    });
  });
}
