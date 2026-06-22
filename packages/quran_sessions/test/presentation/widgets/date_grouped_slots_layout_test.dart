import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran_sessions/src/domain/entities/teacher_availability.dart';
import 'package:quran_sessions/src/presentation/utils/teacher_availability_by_date.dart';
import 'package:quran_sessions/src/presentation/widgets/date_grouped_slots_layout.dart';

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
}
