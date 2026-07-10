import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/domain/entities/email_registration_step.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Mirrors [RegisterScreen] footer layout: [Expanded] scroll body + pinned
/// primary CTA via [TilawaBottomActionInset].
class _RegistrationFormFooterHarness extends StatelessWidget {
  const _RegistrationFormFooterHarness({
    required this.primaryLabel,
    this.errorMessage,
  });

  final String primaryLabel;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;

    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: tokens.spaceLarge,
                    bottom: tokens.spaceMedium,
                  ),
                  child: Text(errorMessage ?? 'Review content'),
                ),
              ),
            ),
          ),
          TilawaBottomActionInset(
            top: tokens.spaceLarge,
            maxWidthKind: TilawaContentKind.form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: tokens.spaceSmall,
              children: <Widget>[
                if (errorMessage != null) Text(errorMessage!),
                TilawaButton(
                  text: primaryLabel,
                  isFullWidth: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  test('registration wizard has three steps without quran learning', () {
    expect(EmailRegistrationStep.values.length, 3);
    expect(
      EmailRegistrationStep.values.map((EmailRegistrationStep s) => s.name),
      <String>['account', 'personal', 'review'],
    );
  });

  testWidgets(
    'profile persistence footer keeps retry button compact in Arabic',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(
            primaryColor: PrimaryColorPreset.defaultPreset.value,
          ),
          home: const _RegistrationFormFooterHarness(
            primaryLabel: 'إعادة حفظ الملف الشخصي',
            errorMessage: 'تم إنشاء الحساب لكن حفظ الملف الشخصي فشل.',
          ),
        ),
      );
      await tester.pump();

      final Finder retryButton = find.widgetWithText(
        TilawaButton,
        'إعادة حفظ الملف الشخصي',
      );
      expect(retryButton, findsOneWidget);
      expect(
        tester.getSize(retryButton).height,
        kMeMuslimMinInteractiveDimension,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
