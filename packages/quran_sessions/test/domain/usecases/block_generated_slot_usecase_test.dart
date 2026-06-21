import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../helpers/availability_test_helpers.dart';

void main() {
  late FakeScheduleRepository scheduleRepo;
  late BlockGeneratedSlotUseCase useCase;

  setUpAll(tz_data.initializeTimeZones);

  setUp(() {
    scheduleRepo = FakeScheduleRepository()..schedule = makeWeeklySchedule();
    useCase = BlockGeneratedSlotUseCase(scheduleRepo);
  });

  test('blocks one generated slot via custom override', () async {
    final slotStart = DateTime.utc(2026, 1, 10, 7, 0);

    final result = await useCase(
      teacherId: 'teacher_1',
      slotStartUtc: slotStart,
      slotEndUtc: slotStart.add(const Duration(minutes: 30)),
    );

    check(result.isRight()).isTrue();
    check(scheduleRepo.overrides).length.equals(1);
    check(scheduleRepo.overrides.single.type).equals(OverrideType.custom);
    check(scheduleRepo.overrides.single.intervals).isNotEmpty();
  });
}
