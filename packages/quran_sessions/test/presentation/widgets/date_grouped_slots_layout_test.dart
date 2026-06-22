import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran_sessions/src/domain/entities/teacher_availability.dart';
import 'package:quran_sessions/src/presentation/utils/teacher_availability_by_date.dart';
import 'package:quran_sessions/src/presentation/widgets/date_grouped_day_tab_bar.dart';
import 'package:quran_sessions/src/presentation/widgets/date_grouped_slots_layout.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

TeacherAvailability _slot(DateTime start) => TeacherAvailability(
  slotId: 'id_${start.millisecondsSinceEpoch}',
  teacherId: 'teacher_1',
  startsAt: start,
  endsAt: start.add(const Duration(minutes: 45)),
  isBooked: false,
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  testWidgets('refreshes last selected day after slot removed from list', (
    tester,
  ) async {
    final day1 = _slot(DateTime(2026, 7, 5, 9));
    final lastDayMorning = _slot(DateTime(2026, 7, 6, 9));
    final lastDayLater = _slot(DateTime(2026, 7, 6, 10));
    final slots = ValueNotifier([day1, lastDayMorning, lastDayLater]);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: ValueListenableBuilder<List<TeacherAvailability>>(
            valueListenable: slots,
            builder: (context, list, _) => DateGroupedSlotsLayout(
              slots: list,
              initialDay: localDayKey(lastDayMorning.startsAt),
              slotsForDayBuilder: (context, daySlots) => Column(
                children: [
                  for (final slot in daySlots) Text(slot.slotId),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(lastDayMorning.slotId), findsOneWidget);
    expect(find.text(lastDayLater.slotId), findsOneWidget);

    slots.value = [day1, lastDayLater];
    await tester.pumpAndSettle();

    expect(find.text(lastDayMorning.slotId), findsNothing);
    expect(find.text(lastDayLater.slotId), findsOneWidget);
  });

  testWidgets(
    'scrolls day tab bar when last day removed and selection resets',
    (
      tester,
    ) async {
      tester.view.physicalSize = const Size(200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final slots = ValueNotifier<List<TeacherAvailability>>([
        for (var i = 0; i < 12; i++) _slot(DateTime(2026, 7, 1 + i, 9)),
        _slot(DateTime(2026, 7, 12, 9)),
        _slot(DateTime(2026, 7, 12, 10)),
      ]);
      final lastDay = localDayKey(DateTime(2026, 7, 12));

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          home: Scaffold(
            body: ValueListenableBuilder<List<TeacherAvailability>>(
              valueListenable: slots,
              builder: (context, list, _) => DateGroupedSlotsLayout(
                slots: list,
                initialDay: lastDay,
                slotsForDayBuilder: (context, daySlots) => Column(
                  children: [
                    for (final slot in daySlots) Text(slot.slotId),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final offsetOnLastDay = _tabBarScrollPixels(tester);
      expect(offsetOnLastDay, greaterThan(0));

      slots.value = [
        for (var i = 0; i < 11; i++) _slot(DateTime(2026, 7, 1 + i, 9)),
      ];
      await tester.pumpAndSettle();

      expect(_tabBarScrollPixels(tester), lessThan(offsetOnLastDay));
    },
  );
}

double _tabBarScrollPixels(WidgetTester tester) {
  final scrollableFinder = find.descendant(
    of: find.byType(DateGroupedDayTabBar),
    matching: find.byType(Scrollable),
  );
  return tester.state<ScrollableState>(scrollableFinder).position.pixels;
}
