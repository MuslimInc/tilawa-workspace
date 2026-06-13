import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/whats_new/presentation/widgets/whats_new_sheet_body.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('renders localized highlight bullets', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.primarySage),
        home: const Scaffold(
          body: WhatsNewSheetBody(
            highlights: <String>[
              'Reciters catalog update',
              'Mini player polish',
            ],
          ),
        ),
      ),
    );

    expect(find.text('Reciters catalog update'), findsOneWidget);
    expect(find.text('Mini player polish'), findsOneWidget);
    expect(find.text('•'), findsNWidgets(2));
  });

  testWidgets('renders wrapped highlight with a bullet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.primarySage),
        home: const Scaffold(
          body: SizedBox(
            width: 160,
            child: WhatsNewSheetBody(
              highlights: <String>[
                'A longer highlight that should wrap onto multiple lines',
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('•'), findsOneWidget);
    expect(
      find.textContaining('A longer highlight'),
      findsOneWidget,
    );
  });
}
