import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'fakes/fake_session_repository.dart';

/// In-memory [ScheduleRepository] for tests.
class FakeScheduleRepository implements ScheduleRepository {
  WeeklySchedule? schedule;
  final List<AvailabilityOverride> overrides = [];
  QuranSessionsFailure? failWith;

  @override
  Future<Either<QuranSessionsFailure, WeeklySchedule?>> getSchedule(
    String teacherId,
  ) async {
    if (failWith != null) return Left(failWith!);
    return Right(schedule);
  }

  @override
  Future<Either<QuranSessionsFailure, void>> saveSchedule(
    WeeklySchedule schedule,
  ) async {
    if (failWith != null) return Left(failWith!);
    this.schedule = schedule;
    return const Right(null);
  }

  @override
  Future<Either<QuranSessionsFailure, List<AvailabilityOverride>>> getOverrides(
    String teacherId, {
    DateTime? from,
    DateTime? to,
  }) async {
    if (failWith != null) return Left(failWith!);
    return Right(List.of(overrides));
  }

  @override
  Future<Either<QuranSessionsFailure, void>> saveOverride(
    String teacherId,
    AvailabilityOverride override,
  ) async {
    if (failWith != null) return Left(failWith!);
    overrides
      ..removeWhere((o) => o.dateKey == override.dateKey)
      ..add(override);
    return const Right(null);
  }

  @override
  Future<Either<QuranSessionsFailure, void>> removeOverride(
    String teacherId,
    String dateKey,
  ) async {
    if (failWith != null) return Left(failWith!);
    overrides.removeWhere((o) => o.dateKey == dateKey);
    return const Right(null);
  }
}

GetTeacherAvailabilityUseCase buildGetTeacherAvailabilityUseCase({
  required FakeScheduleRepository scheduleRepository,
  required FakeSessionRepository sessionRepository,
  DateTime Function()? now,
}) => GetTeacherAvailabilityUseCase(
  scheduleRepository: scheduleRepository,
  sessionRepository: sessionRepository,
  now: now,
);

WeeklySchedule makeWeeklySchedule({
  String teacherId = 'teacher_1',
  String timezone = 'Africa/Cairo',
  SlotDuration slotDuration = SlotDuration.thirty,
  Map<Weekday, List<TimeRange>>? rules,
  SchedulingPolicy policy = const SchedulingPolicy(
    minNoticeMinutes: 0,
    maxHorizonDays: 1000,
  ),
}) => WeeklySchedule(
  teacherId: teacherId,
  timezone: timezone,
  slotDuration: slotDuration,
  rules:
      rules ??
      {
        Weekday.saturday: const [
          TimeRange(start: LocalTime(9, 0), end: LocalTime(12, 0)),
        ],
      },
  policy: policy,
);
