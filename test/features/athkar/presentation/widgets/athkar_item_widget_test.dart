import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_item.dart';
import 'package:tilawa/features/athkar/presentation/widgets/athkar_item_widget.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

void main() {
  const tItem = AthkarItem(
    id: 1,
    categoryId: 1,
    textAr: 'سبحان الله',
    textEn: 'Subhan Allah',
    count: 3,
    reference: 'Muslim',
  );

  Widget createWidgetUnderTest({
    required int currentCount,
    required VoidCallback onTap,
    required VoidCallback onReset,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      locale: const Locale('en'),
      home: ScreenUtilPlusInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        child: Scaffold(
          body: AthkarItemWidget(
            item: tItem,
            currentCount: currentCount,
            onTap: onTap,
            onReset: onReset,
          ),
        ),
      ),
    );
  }

  testWidgets('renders text and counter correctly', (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest(currentCount: 3, onTap: () {}, onReset: () {}),
    );
    await tester.pump();

    expect(find.text('سبحان الله'), findsOneWidget);
    expect(find.text('Subhan Allah'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Muslim'), findsOneWidget);
  });

  testWidgets('calls onTap when tapped and not done', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      createWidgetUnderTest(
        currentCount: 3,
        onTap: () => tapped = true,
        onReset: () {},
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(AthkarItemWidget));
    expect(tapped, isTrue);
  });

  testWidgets('calls onReset when long pressed', (tester) async {
    var reset = false;
    await tester.pumpWidget(
      createWidgetUnderTest(
        currentCount: 1,
        onTap: () {},
        onReset: () => reset = true,
      ),
    );
    await tester.pump();

    await tester.longPress(find.byType(AthkarItemWidget));
    expect(reset, isTrue);
  });

  testWidgets('displays "Done" state when currentCount is 0', (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest(currentCount: 0, onTap: () {}, onReset: () {}),
    );
    await tester.pump();

    expect(find.text('Done'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });
}
