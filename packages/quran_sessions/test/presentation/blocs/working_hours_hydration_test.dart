import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_booked_slot_lock_repository.dart';

void _expectWeekdayInvariant(AvailabilityState state) {
  final selected = state.selectedWeekdays.toList()
    ..sort((a, b) => a.index.compareTo(b.index));
  final fromSlots = Weekday.values
      .where((day) => state.draft.rangesFor(day).isNotEmpty)
      .toList();
  check(selected).deepEquals(fromSlots);
  check(state.selectedWeekdays.length).equals(state.draft.openDays.length);
}

void _expectSelectedDays(AvailabilityState state, List<Weekday> expected) {
  _expectWeekdayInvariant(state);
  final selected = state.selectedWeekdays.toList()
    ..sort((a, b) => a.index.compareTo(b.index));
  final sortedExpected = [...expected]
    ..sort((a, b) => a.index.compareTo(b.index));
  check(selected).deepEquals(sortedExpected);
}

AvailabilityCubit _build(FakeScheduleRepository repo) => AvailabilityCubit(
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

Future<AvailabilityCubit> _reopen(FakeScheduleRepository repo) async {
  final cubit = _build(repo);
  await cubit.load('teacher_1');
  return cubit;
}

void main() {
  late FakeScheduleRepository repo;

  setUpAll(() => tz_data.initializeTimeZones());

  setUp(() => repo = FakeScheduleRepository());

  group('Working hours hydration invariant', () {
    test('monday only → save → reopen → only monday selected', () async {
      final cubit = _build(repo);
      await cubit.load('teacher_1');
      cubit.toggleDay(Weekday.monday, true);
      await cubit.save();
      await cubit.close();

      final reopened = await _reopen(repo);
      _expectSelectedDays(reopened.state, [Weekday.monday]);
      check(reopened.state.isDirty).isFalse();
      await reopened.close();
    });

    test('one weekday → navigate away → reopen → persisted weekdays', () async {
      final cubit = _build(repo);
      await cubit.load('teacher_1');
      cubit.toggleDay(Weekday.wednesday, true);
      await cubit.save();
      await cubit.close();

      final reopened = await _reopen(repo);
      _expectSelectedDays(reopened.state, [Weekday.wednesday]);
      await reopened.close();
    });

    test('mon+tue → save → reopen → exactly mon+tue', () async {
      final cubit = _build(repo);
      await cubit.load('teacher_1');
      cubit.toggleDay(Weekday.monday, true);
      cubit.toggleDay(Weekday.tuesday, true);
      await cubit.save();
      await cubit.close();

      final reopened = await _reopen(repo);
      _expectSelectedDays(reopened.state, [Weekday.monday, Weekday.tuesday]);
      await reopened.close();
    });

    test('delete all → save → reopen → zero weekdays', () async {
      repo.schedule = WeeklySchedule(
        teacherId: 'teacher_1',
        timezone: 'Africa/Cairo',
        slotDuration: SlotDuration.thirty,
        rules: {
          for (final day in Weekday.values)
            day: const [
              TimeRange(start: LocalTime(9, 0), end: LocalTime(17, 0)),
            ],
        },
      );
      final cubit = _build(repo);
      await cubit.load('teacher_1');
      for (final day in Weekday.values) {
        cubit.toggleDay(day, false);
      }
      await cubit.save();
      await cubit.close();

      final reopened = await _reopen(repo);
      _expectWeekdayInvariant(reopened.state);
      check(reopened.state.selectedWeekdays).isEmpty();
      await reopened.close();
    });

    test('save → pop → reopen → matches persisted repo snapshot', () async {
      final cubit = _build(repo);
      await cubit.load('teacher_1');
      cubit.toggleDay(Weekday.friday, true);
      await cubit.save();
      final persisted = repo.schedule!;
      await cubit.close();

      final reopened = await _reopen(repo);
      _expectWeekdayInvariant(reopened.state);
      for (final day in Weekday.values) {
        check(reopened.state.draft.rangesFor(day)).deepEquals(
          persisted.rangesFor(day),
        );
      }
      await reopened.close();
    });

    test('refresh after save → weekdays still match persisted', () async {
      final cubit = _build(repo);
      await cubit.load('teacher_1');
      cubit.toggleDay(Weekday.thursday, true);
      await cubit.save();
      await cubit.load('teacher_1');

      _expectWeekdayInvariant(cubit.state);
      _expectSelectedDays(cubit.state, [Weekday.thursday]);
      check(cubit.state.isDirty).isFalse();
      await cubit.close();
    });

    test(
      'toggle same hours on/off → save → reopen → no phantom weekdays',
      () async {
        final cubit = _build(repo);
        await cubit.load('teacher_1');
        cubit.toggleDay(Weekday.monday, true);
        cubit.toggleDay(Weekday.tuesday, true);
        cubit.setUseSameHoursForAllDays(true);
        cubit.setUseSameHoursForAllDays(false);
        await cubit.save();
        await cubit.close();

        final reopened = await _reopen(repo);
        _expectSelectedDays(reopened.state, [Weekday.monday, Weekday.tuesday]);
        await reopened.close();
      },
    );

    test(
      'teacher dashboard open-day count matches working hours selection',
      () async {
        repo.schedule = WeeklySchedule(
          teacherId: 'teacher_1',
          timezone: 'Africa/Cairo',
          slotDuration: SlotDuration.thirty,
          rules: {
            Weekday.monday: const [
              TimeRange(start: LocalTime(9, 0), end: LocalTime(12, 0)),
            ],
            Weekday.wednesday: const [
              TimeRange(start: LocalTime(14, 0), end: LocalTime(16, 0)),
            ],
          },
        );
        final cubit = _build(repo);
        await cubit.load('teacher_1');
        _expectWeekdayInvariant(cubit.state);

        final from = DateTime.utc(2026, 1, 5);
        final to = from.add(const Duration(days: 14));
        final availability = await GetTeacherAvailabilityUseCase(
          scheduleRepository: repo,
          bookedSlotLocks: FakeBookedSlotLockRepository(),
          now: () => from,
        )('teacher_1', from: from, to: to);

        availability.fold(
          (_) => fail('expected availability'),
          (slots) {
            check(cubit.state.selectedWeekdays.length).equals(2);
            check(slots).isNotEmpty();
          },
        );
        await cubit.close();
      },
    );

    test('multiple save/reopen cycles never grow selected weekdays', () async {
      var cubit = _build(repo);
      await cubit.load('teacher_1');
      cubit.toggleDay(Weekday.monday, true);
      await cubit.save();
      check(cubit.state.selectedWeekdays.length).equals(1);
      await cubit.close();

      for (var cycle = 0; cycle < 3; cycle++) {
        cubit = await _reopen(repo);
        _expectWeekdayInvariant(cubit.state);
        check(cubit.state.selectedWeekdays.length).equals(1);
        await cubit.close();
      }
    });

    test(
      'stale overlapping load does not overwrite fresher hydration',
      () async {
        final delayingRepo = _DelayingScheduleRepository();
        final cubit = AvailabilityCubit(
          getSchedule: GetWeeklyScheduleUseCase(delayingRepo),
          saveSchedule: SaveWeeklyScheduleUseCase(
            delayingRepo,
            const WeeklyScheduleValidator(),
          ),
          getOverrides: GetAvailabilityOverridesUseCase(delayingRepo),
          saveOverride: SaveAvailabilityOverrideUseCase(delayingRepo),
          removeOverride: RemoveAvailabilityOverrideUseCase(delayingRepo),
          defaultTimezone: 'Africa/Cairo',
        );

        delayingRepo.schedule = WeeklySchedule(
          teacherId: 'teacher_1',
          timezone: 'Africa/Cairo',
          slotDuration: SlotDuration.thirty,
          rules: {
            for (final day in Weekday.values)
              day: const [
                TimeRange(start: LocalTime(9, 0), end: LocalTime(17, 0)),
              ],
          },
        );
        delayingRepo.delay = const Duration(milliseconds: 50);

        final slow = cubit.load('teacher_1');
        delayingRepo.schedule = WeeklySchedule(
          teacherId: 'teacher_1',
          timezone: 'Africa/Cairo',
          slotDuration: SlotDuration.thirty,
          rules: {
            Weekday.monday: const [
              TimeRange(start: LocalTime(9, 0), end: LocalTime(17, 0)),
            ],
          },
        );
        delayingRepo.delay = Duration.zero;
        await cubit.load('teacher_1');
        await slow;

        _expectWeekdayInvariant(cubit.state);
        _expectSelectedDays(cubit.state, [Weekday.monday]);
        await cubit.close();
      },
    );
  });
}

class _DelayingScheduleRepository implements ScheduleRepository {
  WeeklySchedule? schedule;
  Duration delay = Duration.zero;

  @override
  Future<Either<QuranSessionsFailure, WeeklySchedule?>> getSchedule(
    String teacherId,
  ) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return Right(schedule?.detached());
  }

  @override
  Future<Either<QuranSessionsFailure, void>> saveSchedule(
    WeeklySchedule schedule,
  ) async {
    this.schedule = schedule.detached();
    return const Right(null);
  }

  @override
  Future<Either<QuranSessionsFailure, List<AvailabilityOverride>>> getOverrides(
    String teacherId, {
    DateTime? from,
    DateTime? to,
  }) async => const Right([]);

  @override
  Future<Either<QuranSessionsFailure, AvailabilityOverride?>> getOverrideByDate(
    String teacherId,
    String dateKey,
  ) async => const Right(null);

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
