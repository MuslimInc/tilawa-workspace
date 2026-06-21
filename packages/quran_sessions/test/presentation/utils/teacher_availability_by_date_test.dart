import 'package:checks/checks.dart';
import 'package:quran_sessions/src/domain/entities/teacher_availability.dart';
import 'package:quran_sessions/src/domain/services/teacher_availability_sort.dart';
import 'package:quran_sessions/src/presentation/utils/teacher_availability_by_date.dart';
import 'package:test/test.dart';

TeacherAvailability _slot(DateTime start) => TeacherAvailability(
  slotId: 'id_${start.millisecondsSinceEpoch}',
  teacherId: 't1',
  startsAt: start,
  endsAt: start.add(const Duration(hours: 1)),
  isBooked: false,
);

void main() {
  group('sortTeacherAvailabilityByStart', () {
    test('orders earliest first', () {
      final later = _slot(DateTime.utc(2026, 6, 24, 10));
      final earlier = _slot(DateTime.utc(2026, 6, 22, 9));
      final middle = _slot(DateTime.utc(2026, 6, 23, 14));

      final sorted = sortTeacherAvailabilityByStart([later, earlier, middle]);

      check(
        sorted.map((s) => s.startsAt.millisecondsSinceEpoch).toList(),
      ).deepEquals([
        earlier.startsAt.millisecondsSinceEpoch,
        middle.startsAt.millisecondsSinceEpoch,
        later.startsAt.millisecondsSinceEpoch,
      ]);
    });
  });

  group('groupTeacherAvailabilityByLocalDay', () {
    test('groups by local day and sorts days chronologically', () {
      final day1Morning = _slot(DateTime.utc(2026, 6, 22, 8));
      final day1Afternoon = _slot(DateTime.utc(2026, 6, 22, 14));
      final day2 = _slot(DateTime.utc(2026, 6, 23, 9));

      final grouped = groupTeacherAvailabilityByLocalDay([
        day2,
        day1Afternoon,
        day1Morning,
      ]);

      check(grouped.days.length).equals(2);
      check(grouped.days.first.isBefore(grouped.days.last)).isTrue();
      check(
        grouped.byDay[grouped.days.first]!
            .map((s) => s.startsAt.millisecondsSinceEpoch)
            .toList(),
      ).deepEquals([
        day1Morning.startsAt.millisecondsSinceEpoch,
        day1Afternoon.startsAt.millisecondsSinceEpoch,
      ]);
    });
  });
}
