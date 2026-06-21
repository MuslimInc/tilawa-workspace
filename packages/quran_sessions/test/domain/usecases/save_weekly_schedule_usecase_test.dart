import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:test/test.dart';

/// In-memory [ScheduleRepository] for schedule use case tests.
class _FakeScheduleRepository implements ScheduleRepository {
  WeeklySchedule? schedule;
  QuranSessionsFailure? failOnSave;
  int saveCount = 0;

  @override
  Future<Either<QuranSessionsFailure, WeeklySchedule?>> getSchedule(
    String teacherId,
  ) async => Right(schedule);

  @override
  Future<Either<QuranSessionsFailure, void>> saveSchedule(
    WeeklySchedule schedule,
  ) async {
    if (failOnSave != null) return Left(failOnSave!);
    this.schedule = schedule;
    saveCount++;
    return const Right(null);
  }

  @override
  Future<Either<QuranSessionsFailure, List<AvailabilityOverride>>> getOverrides(
    String teacherId, {
    DateTime? from,
    DateTime? to,
  }) async => const Right([]);

  @override
  Future<Either<QuranSessionsFailure, void>> saveOverride(
    String teacherId,
    AvailabilityOverride override,
  ) async => const Right(null);

  @override
  Future<Either<QuranSessionsFailure, void>> removeOverride(
    String teacherId,
    String dateKey,
  ) async => const Right(null);
}

void main() {
  late _FakeScheduleRepository repo;
  late SaveWeeklyScheduleUseCase saveSchedule;
  late GetWeeklyScheduleUseCase getSchedule;

  WeeklySchedule baseline() => WeeklySchedule.empty(
    teacherId: 'teacher_1',
    timezone: 'Africa/Cairo',
  );

  WeeklySchedule draftWithSaturday() => baseline().withDay(
    Weekday.saturday,
    const [TimeRange(start: LocalTime(9, 0), end: LocalTime(17, 0))],
  );

  setUp(() {
    repo = _FakeScheduleRepository();
    const validator = WeeklyScheduleValidator();
    saveSchedule = SaveWeeklyScheduleUseCase(repo, validator);
    getSchedule = GetWeeklyScheduleUseCase(repo);
  });

  group('SaveWeeklyScheduleUseCase', () {
    test('persists valid draft and returns reloaded schedule', () async {
      final baselineSchedule = baseline();
      repo.schedule = baselineSchedule;

      final result = await saveSchedule(
        draft: draftWithSaturday(),
        baseline: baselineSchedule,
      );

      check(repo.saveCount).equals(1);
      check(result.isRight()).isTrue();
      result.fold(
        (_) => fail('expected Right'),
        (synced) {
          check(synced.isOpenOn(Weekday.saturday)).isTrue();
          check(synced.version).equals(2);
        },
      );
    });

    test('does not persist invalid draft', () async {
      final result = await saveSchedule(
        draft: baseline(),
        baseline: baseline(),
      );

      check(repo.saveCount).equals(0);
      check(result.isLeft()).isTrue();
      result.fold(
        (failure) => check(failure).isA<ValidationFailure>(),
        (_) => fail('expected Left'),
      );
    });

    test('returns failure when repository save fails', () async {
      repo.failOnSave = const NetworkFailure();
      final baselineSchedule = baseline();

      final result = await saveSchedule(
        draft: draftWithSaturday(),
        baseline: baselineSchedule,
      );

      check(repo.saveCount).equals(0);
      check(result.isLeft()).isTrue();
      result.fold(
        (failure) => check(failure).isA<NetworkFailure>(),
        (_) => fail('expected Left'),
      );
    });
  });

  group('GetWeeklyScheduleUseCase', () {
    test('returns empty template when repository has no schedule', () async {
      final result = await getSchedule(
        'teacher_1',
        defaultTimezone: 'Asia/Riyadh',
      );

      check(result.isRight()).isTrue();
      result.fold(
        (_) => fail('expected Right'),
        (schedule) {
          check(schedule.isEmpty).isTrue();
          check(schedule.timezone).equals('Asia/Riyadh');
        },
      );
    });

    test('returns saved schedule from repository', () async {
      repo.schedule = baseline().copyWith(timezone: 'Europe/London');

      final result = await getSchedule(
        'teacher_1',
        defaultTimezone: 'Africa/Cairo',
      );

      result.fold(
        (_) => fail('expected Right'),
        (schedule) => check(schedule.timezone).equals('Europe/London'),
      );
    });
  });
}
