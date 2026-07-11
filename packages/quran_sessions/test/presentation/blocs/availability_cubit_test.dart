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
  Future<Either<QuranSessionsFailure, AvailabilityOverride?>> getOverrideByDate(
    String teacherId,
    String dateKey,
  ) async {
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

  AvailabilityCubit build() => AvailabilityCubit(
    getSchedule: GetWeeklyScheduleUseCase(repo),
    saveSchedule: SaveWeeklyScheduleUseCase(
      repo,
      const WeeklyScheduleValidator(),
    ),
    getOverrides: GetAvailabilityOverridesUseCase(repo),
    saveOverride: SaveAvailabilityOverrideUseCase(repo),
    removeOverride: RemoveAvailabilityOverrideUseCase(repo),
    defaultTimezone: 'Africa/Cairo',
  );

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

    test('does not save when there are no unsaved changes', () async {
      final cubit = build();
      await cubit.load('teacher_1');

      await cubit.save();

      check(repo.saveCount).equals(0);
      check(cubit.state.saveTick).equals(0);
    });

    test('rejects invalid draft without calling repository', () async {
      repo.schedule = WeeklySchedule(
        teacherId: 'teacher_1',
        timezone: 'Africa/Cairo',
        slotDuration: SlotDuration.thirty,
        rules: {
          Weekday.saturday: const [
            TimeRange(start: LocalTime(9, 0), end: LocalTime(17, 0)),
          ],
        },
      );
      final cubit = build();
      await cubit.load('teacher_1');
      cubit.addRange(
        Weekday.saturday,
        const TimeRange(start: LocalTime(16, 0), end: LocalTime(10, 0)),
      );

      await cubit.save();

      check(repo.saveCount).equals(0);
      check(cubit.state.saveEnabled).isFalse();
      check(cubit.state.isDirty).isTrue();
      check(cubit.state.failure).isNull();
    });

    test('ignores duplicate save while already saving', () async {
      final cubit = build();
      await cubit.load('teacher_1');
      cubit.toggleDay(Weekday.saturday, true);

      final first = cubit.save();
      await cubit.save();
      await first;

      check(repo.saveCount).equals(1);
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
      check(cubit.state.overrideRemoveTick).equals(1);
    });

    test('addOverrides persists a vacation date range', () async {
      final cubit = build();
      await cubit.load('teacher_1');

      await cubit.addOverrides([
        for (var day = 24; day <= 26; day++)
          AvailabilityOverride(
            date: DateTime(2026, 6, day),
            type: OverrideType.unavailable,
            reason: 'vacation',
          ),
      ]);

      check(cubit.state.overrides).length.equals(3);
      check(repo.overrides).length.equals(3);

      await cubit.removeOverrides(['2026-06-24', '2026-06-25', '2026-06-26']);
      check(cubit.state.overrides).isEmpty();
      check(cubit.state.overrideRemoveTick).equals(1);
    });

    test(
      'addOverrides rejects overlapping vacation without persisting',
      () async {
        repo.overrides.add(
          AvailabilityOverride(
            date: DateTime(2026, 6, 25),
            type: OverrideType.unavailable,
            reason: 'vacation',
          ),
        );
        final cubit = build();
        await cubit.load('teacher_1');

        await cubit.addOverrides([
          for (var day = 24; day <= 26; day++)
            AvailabilityOverride(
              date: DateTime(2026, 6, day),
              type: OverrideType.unavailable,
              reason: 'vacation',
            ),
        ]);

        check(cubit.state.overrides).length.equals(1);
        check(repo.overrides).length.equals(1);
        check(cubit.state.failure).isA<ValidationFailure>();
        check(cubit.state.isOverridesBusy).isFalse();
      },
    );

    test('addOverrides increments overrideAddTick on success', () async {
      final cubit = build();
      await cubit.load('teacher_1');

      await cubit.addOverrides([
        AvailabilityOverride(
          date: DateTime(2026, 6, 30),
          type: OverrideType.unavailable,
          reason: 'vacation',
        ),
      ]);

      check(cubit.state.overrideAddTick).equals(1);
      check(cubit.state.isOverridesBusy).isFalse();
    });

    test(
      'addOverrides allows custom hours on vacation-blocked dates',
      () async {
        repo.overrides.add(
          AvailabilityOverride(
            date: DateTime(2026, 6, 25),
            type: OverrideType.unavailable,
            reason: 'vacation',
          ),
        );
        final cubit = build();
        await cubit.load('teacher_1');

        await cubit.addOverrides([
          AvailabilityOverride(
            date: DateTime(2026, 6, 25),
            type: OverrideType.custom,
          ),
        ]);

        check(cubit.state.overrides).length.equals(1);
        check(cubit.state.overrides.single.type).equals(OverrideType.custom);
        check(cubit.state.failure).isNull();
      },
    );
  });

  group('working hours regression', () {
    WeeklySchedule uniformSevenDaySchedule() => WeeklySchedule(
      teacherId: 'teacher_1',
      timezone: 'Africa/Cairo',
      slotDuration: SlotDuration.thirty,
      rules: {
        for (final day in Weekday.values)
          day: const [TimeRange(start: LocalTime(9, 0), end: LocalTime(17, 0))],
      },
    );

    test(
      'delete all slots then reopen shows no stale selected days',
      () async {
        repo.schedule = uniformSevenDaySchedule();
        final cubit = build();
        await cubit.load('teacher_1');
        for (final day in Weekday.values) {
          cubit.toggleDay(day, false);
        }
        await cubit.save();
        await cubit.load('teacher_1');

        check(cubit.state.draft.openDays).isEmpty();
        check(cubit.state.baseline.openDays).isEmpty();
        check(cubit.state.isDirty).isFalse();
      },
    );

    test('delete all then add valid slot enables save', () async {
      repo.schedule = uniformSevenDaySchedule();
      final cubit = build();
      await cubit.load('teacher_1');
      for (final day in Weekday.values) {
        cubit.toggleDay(day, false);
      }
      await cubit.save();
      await cubit.load('teacher_1');

      cubit.toggleDay(Weekday.monday, true);
      check(cubit.state.isDirty).isTrue();
      check(cubit.state.draft.isOpenOn(Weekday.monday)).isTrue();
    });

    test('reopen weekdays match backend schedule', () async {
      repo.schedule = WeeklySchedule(
        teacherId: 'teacher_1',
        timezone: 'Africa/Cairo',
        slotDuration: SlotDuration.thirty,
        rules: {
          Weekday.tuesday: const [
            TimeRange(start: LocalTime(10, 0), end: LocalTime(14, 0)),
          ],
          Weekday.thursday: const [
            TimeRange(start: LocalTime(18, 0), end: LocalTime(20, 0)),
          ],
        },
      );
      final cubit = build();
      await cubit.load('teacher_1');
      cubit.toggleDay(Weekday.tuesday, false);

      await cubit.load('teacher_1');

      check(cubit.state.draft.isOpenOn(Weekday.tuesday)).isTrue();
      check(cubit.state.draft.isOpenOn(Weekday.thursday)).isTrue();
      check(cubit.state.draft.isOpenOn(Weekday.monday)).isFalse();
      check(cubit.state.isDirty).isFalse();
    });

    test(
      'add slot after empty marks dirty without unrelated field change',
      () async {
        final cubit = build();
        await cubit.load('teacher_1');
        cubit.toggleDay(Weekday.wednesday, true);
        cubit.addRange(
          Weekday.wednesday,
          const TimeRange(start: LocalTime(18, 0), end: LocalTime(20, 0)),
        );

        check(cubit.state.isDirty).isTrue();
        check(cubit.state.draft.rangesFor(Weekday.wednesday)).length.equals(2);
      },
    );

    test('overlapping draft ranges disable save until fixed', () async {
      final cubit = build();
      await cubit.load('teacher_1');
      cubit.toggleDay(Weekday.monday, true);
      cubit.addRange(
        Weekday.monday,
        const TimeRange(start: LocalTime(9, 0), end: LocalTime(12, 0)),
      );
      cubit.addRange(
        Weekday.monday,
        const TimeRange(start: LocalTime(10, 0), end: LocalTime(14, 0)),
      );

      check(cubit.state.isDirty).isTrue();
      check(cubit.state.isDraftValid).isFalse();
      check(cubit.state.saveEnabled).isFalse();
    });

    test('cancel after edits resets draft to baseline', () async {
      repo.schedule = uniformSevenDaySchedule();
      final cubit = build();
      await cubit.load('teacher_1');
      cubit.toggleDay(Weekday.saturday, false);
      check(cubit.state.isDirty).isTrue();

      cubit.discardChanges();

      check(cubit.state.isDirty).isFalse();
      check(cubit.state.draft).equals(cubit.state.baseline);
      check(cubit.state.draft.isOpenOn(Weekday.saturday)).isTrue();
    });

    test('load keeps baseline isolated from draft edits', () async {
      repo.schedule = uniformSevenDaySchedule();
      final cubit = build();
      await cubit.load('teacher_1');
      cubit.toggleDay(Weekday.saturday, false);

      check(cubit.state.baseline.isOpenOn(Weekday.saturday)).isTrue();
      check(cubit.state.draft.isOpenOn(Weekday.saturday)).isFalse();
    });

    test('reload discards unsaved local edits', () async {
      repo.schedule = uniformSevenDaySchedule();
      final cubit = build();
      await cubit.load('teacher_1');
      cubit.toggleDay(Weekday.saturday, false);
      check(cubit.state.isDirty).isTrue();

      await cubit.load('teacher_1');

      check(cubit.state.draft.isOpenOn(Weekday.saturday)).isTrue();
      check(cubit.state.isDirty).isFalse();
    });
  });
}
