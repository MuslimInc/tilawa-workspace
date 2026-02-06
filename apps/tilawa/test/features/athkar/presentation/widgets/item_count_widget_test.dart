import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_item.dart';
import 'package:tilawa/features/athkar/presentation/widgets/item_count_widget.dart';

void main() {
  const testItem = AthkarItem(
    id: 1,
    categoryId: 1,
    count: 3,
    textEn: 'Test English Text',
    reference: 'Test Reference',
    textAr: 'Test Arabic Text',
  );

  testWidgets('ItemCountWidget displays correct count and progress', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return const MaterialApp(
            home: Scaffold(
              body: ItemCountWidget(
                item: testItem,
                currentCount: 3,
                isDone: false,
              ),
            ),
          );
        },
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ItemCountWidget displays checkmark when done', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return const MaterialApp(
            home: Scaffold(
              body: ItemCountWidget(
                item: testItem,
                currentCount: 0,
                isDone: true,
              ),
            ),
          );
        },
      ),
    );

    expect(find.byIcon(FluentIcons.checkmark_24_filled), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('ItemCountWidget updates count correctly', (
    WidgetTester tester,
  ) async {
    var currentCount = 3;
    late StateSetter setTestState;

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  setTestState = setState;
                  return ItemCountWidget(
                    item: testItem,
                    currentCount: currentCount,
                    isDone: false,
                  );
                },
              ),
            ),
          );
        },
      ),
    );

    expect(find.text('3'), findsOneWidget);

    // Update count using setState
    setTestState(() {
      currentCount = 2;
    });

    await tester.pump(); // Implicit animations like AnimatedSwitcher start here

    expect(find.text('2'), findsOneWidget);
  });
}
