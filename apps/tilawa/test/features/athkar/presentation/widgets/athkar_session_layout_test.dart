import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_item.dart';
import 'package:tilawa/features/athkar/presentation/widgets/athkar_index_sheet.dart';
import 'package:tilawa/features/athkar/presentation/widgets/athkar_item_widget.dart';
import 'package:tilawa/features/athkar/presentation/widgets/athkar_session_bottom_bar.dart';
import 'package:tilawa/features/athkar/presentation/widgets/athkar_session_count_button.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart' show AppTheme;

const AthkarItem _sampleItem = AthkarItem(
  id: 1,
  categoryId: 10,
  textAr: 'بسم الله الرحمن الرحيم\nقل هو الله أحد',
  textEn: 'In the name of Allah',
  count: 3,
  reference: 'الإخلاص',
);

const AthkarItem _sampleItemTwo = AthkarItem(
  id: 2,
  categoryId: 10,
  textAr: 'آية الكرسي',
  textEn: 'Ayat al-Kursi',
  count: 1,
  reference: '',
);

Widget _harness({required Widget child}) {
  return MaterialApp(
    theme: AppTheme.getLightTheme(
      primaryColor: PrimaryColorPreset.defaultPreset.value,
    ),
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('AthkarItemWidget', () {
    testWidgets('shows reference and repeat count; tap decrements via onTap', (
      WidgetTester tester,
    ) async {
      var taps = 0;

      await tester.pumpWidget(
        _harness(
          child: SizedBox(
            height: 600,
            child: AthkarItemWidget(
              item: _sampleItem,
              onTap: () => taps++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('الإخلاص'), findsOneWidget);
      expect(find.text('3 times'), findsOneWidget);

      await tester.tap(find.textContaining('قل هو الله أحد'));
      await tester.pump();

      expect(taps, 1);
    });
  });

  group('AthkarSessionBottomBar', () {
    testWidgets('count button and share control are present; count taps fire', (
      WidgetTester tester,
    ) async {
      var countTaps = 0;

      await tester.pumpWidget(
        _harness(
          child: AthkarSessionBottomBar(
            item: _sampleItem,
            currentCount: 2,
            currentIndex: 0,
            totalItems: 5,
            onCountTap: () => countTaps++,
            onReset: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5 | 1'), findsOneWidget);
      expect(find.byType(AthkarSessionCountButton), findsOneWidget);
      expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.restart_alt_rounded), findsOneWidget);

      await tester.tap(find.byType(AthkarSessionCountButton));
      await tester.pump();

      expect(countTaps, 1);
    });
  });

  group('AthkarIndexSheet', () {
    testWidgets('highlights current item and returns selection on tap', (
      WidgetTester tester,
    ) async {
      int? selected;

      await tester.pumpWidget(
        _harness(
          child: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  selected = await showAthkarIndexSheet(
                    context: context,
                    items: const [_sampleItem, _sampleItemTwo],
                    currentIndex: 0,
                    categoryName: 'Evening Athkar',
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Search'), findsOneWidget);
      expect(find.text('آية الكرسي'), findsOneWidget);

      await tester.tap(find.text('آية الكرسي'));
      await tester.pumpAndSettle();

      expect(selected, 1);
    });
  });
}
