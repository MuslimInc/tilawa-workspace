import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('renders the canonical quran mark inside a circular badge', (
    WidgetTester tester,
  ) async {
    final ThemeData theme = AppTheme.getLightTheme(
      primaryColor: AppColors.defaultPrimary,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: Center(child: TilawaAppBrandBadge()),
        ),
      ),
    );

    expect(find.byType(TilawaAppBrandBadge), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
  });
}
