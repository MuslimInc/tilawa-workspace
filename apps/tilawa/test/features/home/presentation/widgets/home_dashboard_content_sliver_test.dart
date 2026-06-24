import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_content_sliver.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('uses flat sheet body below hero header', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              HomeDashboardContentSliver(
                child: const Text('sheet body'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ClipPath), findsNothing);
    expect(find.text('sheet body'), findsOneWidget);
  });
}
