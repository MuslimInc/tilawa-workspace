import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

/// In-memory [ScheduleRepository] for cubit tests.
class _FakeScheduleRepository implements ScheduleRepository {
  WeeklySchedule? schedule;
  final List<AvailabilityOverride> overrides = [];
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
  }) async => Right(List.of(overrides));

  @override
  Future<Either<QuranSessionsFailure, void>> saveOverride(
    String teacherId,
    AvailabilityOverride override,
  ) async {
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
    overrides.removeWhere((o) => o.dateKey == dateKey);
    return const Right(null);
  }
}

void main() {
  late _FakeScheduleRepository repo;

  AvailabilityCubit build() =>
      AvailabilityCubit(repository: repo, defaultTimezone: 'Africa/Cairo');

  setUp(() => repo = _FakeScheduleRepository());

  group('load', () {
    test('with no saved schedule → ready, all closed, not dirty', () async {
      final cubit = build();
      await cubit.load('teacher_1');

      check(cubit.state.status).equals(AvailabilityStatus.ready);
      check(cubit.state.draft.isEmpty).isTrue();
      check(cubit.state.draft.timezone).equals('Africa/Cairo');
      check(cubit.state.isDirty).isFalse();
    });

    test('hydrates an existing saved schedule', () async {
      repo.schedule = WeeklySchedule(
        teacherId: 'teacher_1',
        timezone: 'Asia/Riyadh',
        slotDuration: SlotDuration.sixty,
        rules: {
          Weekday.sunday: const [
            TimeRange(start: LocalTime(9, 0), end: LocalTime(12, 0)),
          ],
        },
      );
      final cubit = build();
      await cubit.load('teacher_1');

      check(cubit.state.draft.timezone).equals('Asia/Riyadh');
      check(cubit.state.draft.isOpenOn(Weekday.sunday)).isTrue();
      check(cubit.state.isDirty).isFalse();
    });
  });

  group('editing', () {
    test(
      'toggleDay opens a closed day with default hours and marks dirty',
      () async {
        final cubit = build();
        await cubit.load('teacher_1');

        cubit.toggleDay(Weekday.saturday, true);

        check(cubit.state.draft.isOpenOn(Weekday.saturday)).isTrue();
        check(cubit.state.draft.rangesFor(Weekday.saturday)).deepEquals(const [
          TimeRange(start: LocalTime(9, 0), end: LocalTime(17, 0)),
        ]);
        check(cubit.state.isDirty).isTrue();
      },
    );

    test('toggleDay off closes the day', () async {
      final cubit = build();
      await cubit.load('teacher_1');
      cubit.toggleDay(Weekday.saturday, true);
      cubit.toggleDay(Weekday.saturday, false);

      check(cubit.state.draft.isOpenOn(Weekday.saturday)).isFalse();
    });

    test('addRange and removeRange mutate a day', () async {
      final cubit = build();
      await cubit.load('teacher_1');
      cubit.toggleDay(Weekday.tuesday, true);
      cubit.addRange(
        Weekday.tuesday,
        const TimeRange(start: LocalTime(20, 0), end: LocalTime(22, 0)),
      );

      check(cubit.state.draft.rangesFor(Weekday.tuesday)).length.equals(2);

      cubit.removeRange(Weekday.tuesday, 0);
      check(cubit.state.draft.rangesFor(Weekday.tuesday)).deepEquals(const [
        TimeRange(start: LocalTime(20, 0), end: LocalTime(22, 0)),
      ]);
    });

    test('setDuration changes the draft duration', () async {
      final cubit = build();
      await cubit.load('teacher_1');
      cubit.setDuration(SlotDuration.fifteen);

      check(cubit.state.draft.slotDuration).equals(SlotDuration.fifteen);
      check(cubit.state.isDirty).isTrue();
    });

    test(
      'same-hours mode applies one set of hours to every open day',
      () async {
        final cubit = build();
        await cubit.load('teacher_1');
        cubit.toggleDay(Weekday.saturday, true);
        cubit.toggleDay(Weekday.sunday, true);

        cubit.setUseSameHoursForAllDays(true);
        cubit.addRange(
          Weekday.saturday,
          const TimeRange(start: LocalTime(18, 0), end: LocalTime(20, 0)),
        );

        // The evening range propagates to Sunday too.
        check(cubit.state.draft.rangesFor(Weekday.sunday)).deepEquals(
          cubit.state.draft.rangesFor(Weekday.saturday),
        );
        check(
          cubit.state.draft
              .rangesFor(Weekday.sunday)
              .any(
                (r) => r.start == const LocalTime(18, 0),
              ),
        ).isTrue();
      },
    );
  });

  group('save', () {
    test(
      'persists, clears dirty, bumps version, increments saveTick',
      () async {
        final cubit = build();
        await cubit.load('teacher_1');
        cubit.toggleDay(Weekday.saturday, true);
        check(cubit.state.isDirty).isTrue();

        await cubit.save();

        check(repo.saveCount).equals(1);
        check(cubit.state.isDirty).isFalse();
        check(cubit.state.saveTick).equals(1);
        check(cubit.state.baseline.version).equals(2); // empty(1) → saved(2)
        check(repo.schedule!.isOpenOn(Weekday.saturday)).isTrue();
      },
    );

    test('keeps edits and surfaces failure when the repo fails', () async {
      repo.failOnSave = const NetworkFailure();
      final cubit = build();
      await cubit.load('teacher_1');
      cubit.toggleDay(Weekday.saturday, true);

      await cubit.save();

      check(cubit.state.failure).isA<NetworkFailure>();
      check(cubit.state.isDirty).isTrue();
      check(cubit.state.saveTick).equals(0);
    });
  });

  group('overrides', () {
    test('addOverride persists immediately and appears in state', () async {
      final cubit = build();
      await cubit.load('teacher_1');

      await cubit.addOverride(
        AvailabilityOverride(
          date: DateTime(2026, 6, 30),
          type: OverrideType.unavailable,
          reason: 'vacation',
        ),
      );

      check(cubit.state.overrides).length.equals(1);
      check(repo.overrides).length.equals(1);

      await cubit.removeOverride('2026-06-30');
      check(cubit.state.overrides).isEmpty();
    });
  });
}
