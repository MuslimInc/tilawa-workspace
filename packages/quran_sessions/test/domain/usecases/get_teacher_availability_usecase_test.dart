import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fixtures.dart';

void main() {
  late FakeScheduleRepository scheduleRepo;
  late FakeSessionRepository sessionRepo;
  late GetTeacherAvailabilityUseCase useCase;

  final fixedNow = DateTime.utc(2026, 1, 9);
  final windowFrom = DateTime.utc(2026, 1, 10);
  final windowTo = DateTime.utc(2026, 1, 17);

  setUpAll(tz_data.initializeTimeZones);

  setUp(() {
    scheduleRepo = FakeScheduleRepository();
    sessionRepo = FakeSessionRepository();
    useCase = buildGetTeacherAvailabilityUseCase(
      scheduleRepository: scheduleRepo,
      sessionRepository: sessionRepo,
      now: () => fixedNow,
    );
  });

  group('GetTeacherAvailabilityUseCase', () {
    test('returns empty list when teacher has no weekly schedule', () async {
      final result = await useCase(
        'teacher_1',
        from: windowFrom,
        to: windowTo,
      );

      check(result.isRight()).isTrue();
      result.fold(
        (_) => fail('expected Right'),
        (slots) => check(slots).isEmpty(),
      );
    });

    test('generates slots from saved weekly schedule', () async {
      scheduleRepo.schedule = makeWeeklySchedule();

      final result = await useCase(
        'teacher_1',
        from: windowFrom,
        to: windowTo,
      );

      result.fold(
        (_) => fail('expected Right'),
        (slots) {
          check(slots).isNotEmpty();
          check(slots.first.slotId).equals(
            GeneratedSlot.deterministicId(
              'teacher_1',
              DateTime.utc(2026, 1, 10, 7, 0),
            ),
          );
        },
      );
    });

    test('removes slots on vacation overrides', () async {
      scheduleRepo.schedule = makeWeeklySchedule();
      scheduleRepo.overrides.add(
        AvailabilityOverride(
          date: DateTime(2026, 1, 10),
          type: OverrideType.unavailable,
          reason: 'vacation',
        ),
      );

      final result = await useCase(
        'teacher_1',
        from: windowFrom,
        to: windowTo,
      );

      result.fold(
        (_) => fail('expected Right'),
        (slots) => check(slots).isEmpty(),
      );
    });

    test('removes slots already booked via teacher sessions', () async {
      scheduleRepo.schedule = makeWeeklySchedule();
      sessionRepo.sessions = [
        makeSession(
          teacherId: 'teacher_1',
          startsAt: DateTime.utc(2026, 1, 10, 7, 0),
        ),
      ];

      final result = await useCase(
        'teacher_1',
        from: windowFrom,
        to: windowTo,
      );

      result.fold(
        (_) => fail('expected Right'),
        (slots) {
          check(
            slots.any(
              (slot) =>
                  slot.startsAt.toUtc() == DateTime.utc(2026, 1, 10, 7, 0),
            ),
          ).isFalse();
        },
      );
    });

    test(
      'applies override on last calendar day of availability window',
      () async {
        scheduleRepo.schedule = makeWeeklySchedule();
        final windowFrom = DateTime.utc(2026, 1, 10);
        // Same calendar day as [windowTo] — repository `to` is exclusive on dates.
        final windowTo = DateTime.utc(2026, 1, 17, 15, 0);
        scheduleRepo.overrides.add(
          AvailabilityOverride(
            date: DateTime(2026, 1, 17),
            type: OverrideType.unavailable,
            reason: 'blocked_last_day',
          ),
        );

        final result = await useCase(
          'teacher_1',
          from: windowFrom,
          to: windowTo,
        );

        result.fold(
          (_) => fail('expected Right'),
          (slots) {
            check(
              slots.any((slot) {
                final utc = slot.startsAt.toUtc();
                return utc.year == 2026 && utc.month == 1 && utc.day == 17;
              }),
            ).isFalse();
          },
        );
      },
    );

    test('converts teacher timezone to UTC slot instants', () async {
      scheduleRepo.schedule = makeWeeklySchedule(
        timezone: 'America/New_York',
        rules: {
          Weekday.saturday: const [
            TimeRange(start: LocalTime(9, 0), end: LocalTime(10, 0)),
          ],
        },
      );

      final result = await useCase(
        'teacher_1',
        from: DateTime.utc(2026, 1, 10),
        to: DateTime.utc(2026, 1, 11),
      );

      result.fold(
        (_) => fail('expected Right'),
        (slots) {
          check(slots.first.startsAt.toUtc().millisecondsSinceEpoch).equals(
            DateTime.utc(2026, 1, 10, 14, 0).millisecondsSinceEpoch,
          );
        },
      );
    });
  });
}
