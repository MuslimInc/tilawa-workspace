import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'fakes/fake_session_repository.dart';

/// In-memory [ScheduleRepository] for tests.
class FakeScheduleRepository implements ScheduleRepository {
  WeeklySchedule? schedule;
  final List<AvailabilityOverride> overrides = [];
  QuranSessionsFailure? failWith;
  int getOverridesCallCount = 0;
  int getOverrideByDateCallCount = 0;
  bool? lastGetOverridesHadDateBounds;

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
    getOverridesCallCount++;
    lastGetOverridesHadDateBounds = from != null || to != null;
    if (failWith != null) return Left(failWith!);
    final fromDate = from == null
        ? null
        : DateTime(from.year, from.month, from.day);
    final toDate = to == null ? null : DateTime(to.year, to.month, to.day);
    final filtered = overrides.where((o) {
      if (fromDate != null && o.date.isBefore(fromDate)) return false;
      if (toDate != null && !o.date.isBefore(toDate)) return false;
      return true;
    }).toList();
    return Right(filtered);
  }

  @override
  Future<Either<QuranSessionsFailure, AvailabilityOverride?>> getOverrideByDate(
    String teacherId,
    String dateKey,
  ) async {
    getOverrideByDateCallCount++;
    if (failWith != null) return Left(failWith!);
    for (final override in overrides) {
      if (override.dateKey == dateKey) return Right(override);
    }
    return const Right(null);
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

/// Wraps [GetTeacherAvailabilityUseCase] to count [call] invocations in tests.
class SpyGetTeacherAvailabilityUseCase extends GetTeacherAvailabilityUseCase {
  SpyGetTeacherAvailabilityUseCase({
    required super.scheduleRepository,
    required super.sessionRepository,
    super.now,
  });

  int callCount = 0;

  @override
  Future<Either<QuranSessionsFailure, List<TeacherAvailability>>> call(
    String teacherId, {
    required DateTime from,
    required DateTime to,
  }) async {
    callCount++;
    return super.call(teacherId, from: from, to: to);
  }
}

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
