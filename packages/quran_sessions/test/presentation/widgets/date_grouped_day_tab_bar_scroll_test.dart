import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran_sessions/src/presentation/widgets/date_grouped_day_tab_bar.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  group('computeDateGroupedDayTabBarScrollTarget', () {
    const viewportWidth = 200.0;
    const maxScroll = 500.0;

    test('returns null when chip already centered', () {
      check(
        computeDateGroupedDayTabBarScrollTarget(
          index: 1,
          viewportWidth: viewportWidth,
          currentOffset: 0,
          maxScrollExtent: maxScroll,
        ),
      ).isNull();
    });

    test('scrolls forward when selected chip past viewport', () {
      check(
        computeDateGroupedDayTabBarScrollTarget(
          index: 10,
          viewportWidth: viewportWidth,
          currentOffset: 0,
          maxScrollExtent: maxScroll,
        ),
      ).isNotNull();
    });

    test('scrolls backward when selected chip before viewport', () {
      check(
        computeDateGroupedDayTabBarScrollTarget(
          index: 0,
          viewportWidth: viewportWidth,
          currentOffset: 200,
          maxScrollExtent: maxScroll,
        ),
      ).equals(0);
    });
  });

  testWidgets('scrolls selected day chip into view when selection changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final days = List<DateTime>.generate(
      15,
      (i) => DateTime(2026, 7, 1 + i),
    );
    var selected = days.last;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: DateGroupedDayTabBar(
                days: days,
                selected: selected,
                onDaySelected: (day) => setState(() => selected = day),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final lastDayOffset = _tabBarScrollPixels(tester);
    check(lastDayOffset).isGreaterThan(0.0);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        home: Scaffold(
          body: DateGroupedDayTabBar(
            days: days,
            selected: days.first,
            onDaySelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    check(_tabBarScrollPixels(tester)).isLessThan(lastDayOffset);
  });
}

double _tabBarScrollPixels(WidgetTester tester) {
  final scrollableFinder = find.descendant(
    of: find.byType(DateGroupedDayTabBar),
    matching: find.byType(Scrollable),
  );
  return tester.state<ScrollableState>(scrollableFinder).position.pixels;
}
