import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Mirrors [RegisterScreen] footer layout: [Expanded] scroll body + full-width
/// primary CTA in a [Column] (non-flex children get unbounded max height).
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
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  child: Text(errorMessage ?? 'Review content'),
                ),
              ),
              if (errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(bottom: tokens.spaceMedium),
                  child: Text(errorMessage!),
                ),
              SizedBox(height: tokens.spaceMedium),
              TilawaButton(
                text: primaryLabel,
                isFullWidth: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets(
    'profile persistence footer keeps retry button compact in Arabic',
    (
      WidgetTester tester,
    ) async {
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

  testWidgets('market data error state keeps retry button compact in Arabic', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: PrimaryColorPreset.defaultPreset.value,
        ),
        home: Scaffold(
          appBar: AppBar(title: const Text('إنشاء حساب')),
          body: SafeArea(
            child: TilawaErrorState(
              icon: Icons.cloud_off_outlined,
              title: 'حدث خطأ ما. يرجى المحاولة مرة أخرى.',
              retryLabel: 'إعادة المحاولة',
              onRetry: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final Finder retryButton = find.widgetWithText(
      TilawaButton,
      'إعادة المحاولة',
    );
    expect(retryButton, findsOneWidget);
    expect(tester.getSize(retryButton).height, lessThan(80));
    expect(tester.takeException(), isNull);
  });
}
