import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/domain/entities/local_time.dart';
import 'package:quran_sessions/src/domain/entities/time_range.dart';
import 'package:quran_sessions/src/presentation/widgets/availability_day_hours_row.dart';

import '../../helpers/widget_pump.dart';

const _sampleRanges = <TimeRange>[
  TimeRange(
    start: LocalTime(9, 0),
    end: LocalTime(17, 0),
  ),
  TimeRange(
    start: LocalTime(2, 30),
    end: LocalTime(5, 0),
  ),
  TimeRange(
    start: LocalTime(4, 45),
    end: LocalTime(8, 0),
  ),
];

Future<void> pumpAvailabilityDayHoursRow(
  WidgetTester tester, {
  required List<TimeRange> ranges,
  required String label,
}) async {
  await pumpInApp(
    tester,
    Padding(
      padding: const EdgeInsets.all(16),
      child: AvailabilityDayHoursRow(
        label: label,
        ranges: ranges,
        onAddRange: () {},
        onEditRange: (_) {},
        onRemoveRange: (_) {},
      ),
    ),
    locale: const Locale('ar'),
    textDirection: TextDirection.rtl,
    surfaceSize: const Size(390, 260),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AvailabilityDayHoursRow goldens', () {
    testWidgets('single range ar rtl light', (tester) async {
      await pumpAvailabilityDayHoursRow(
        tester,
        label: 'الساعات',
        ranges: const [
          TimeRange(
            start: LocalTime(9, 0),
            end: LocalTime(17, 0),
          ),
        ],
      );

      await expectLater(
        find.byType(AvailabilityDayHoursRow),
        matchesGoldenFile('goldens/availability_day_hours_row_ar_single.png'),
      );
    });

    testWidgets('wrapped ranges ar rtl light', (tester) async {
      await pumpAvailabilityDayHoursRow(
        tester,
        label: 'الساعات',
        ranges: _sampleRanges,
      );

      await expectLater(
        find.byType(AvailabilityDayHoursRow),
        matchesGoldenFile('goldens/availability_day_hours_row_ar_wrap.png'),
      );
    });
  });

  group('AvailabilityDayHoursRow layout contracts', () {
    testWidgets('add button matches pill height and stays compact', (
      tester,
    ) async {
      await pumpAvailabilityDayHoursRow(
        tester,
        label: 'الساعات',
        ranges: _sampleRanges,
      );

      final pill = tester.getSize(find.byType(AvailabilityRangePill).first);
      final addButton = tester.getSize(find.byType(AvailabilityAddRangeButton));

      expect(addButton.height, pill.height);
      expect(addButton.width, lessThan(pill.width));
      expect(addButton.width, lessThan(80));
    });
  });
}
