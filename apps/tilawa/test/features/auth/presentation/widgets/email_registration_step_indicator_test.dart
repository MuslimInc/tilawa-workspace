import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/presentation/widgets/email_registration_step_indicator.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('first step shows underway progress not cold zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: PrimaryColorPreset.defaultPreset.value,
        ),
        home: const Scaffold(
          body: EmailRegistrationStepIndicator(
            currentStep: 1,
            totalSteps: 3,
            stepLabel: 'Step 1 of 3: Your account',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final LinearProgressIndicator bar = tester.widget(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(1 / 3, 0.001));
    expect(find.text('Step 1 of 3: Your account'), findsOneWidget);
  });
}
