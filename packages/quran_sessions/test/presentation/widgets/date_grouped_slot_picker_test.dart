import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/widget_pump.dart';

void main() {
  testWidgets('shows local timezone note above slot grid', (tester) async {
    final slot = makeSlot(
      startsAt: DateTime.now().add(const Duration(days: 1)),
    );

    await pumpInApp(
      tester,
      DateGroupedSlotPicker(
        slots: [slot],
        selectedSlotId: null,
        onSlotSelected: (_) {},
      ),
      surfaceSize: const Size(360, 640),
    );

    expect(
      find.text('Times are shown in your local timezone'),
      findsOneWidget,
    );
  });
}
