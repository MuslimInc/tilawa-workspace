import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/onboarding/presentation/widgets/onboarding_device_frame.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  ThemeData themeFor(TargetPlatform platform) => AppTheme.getLightTheme(
    primaryColor: PrimaryColorPreset.defaultPreset.value,
  ).copyWith(platform: platform);

  Future<void> pumpFrame(
    WidgetTester tester, {
    required TargetPlatform platform,
    TargetPlatform? platformOverride,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: themeFor(platform),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              child: OnboardingDeviceFrame(
                platformOverride: platformOverride,
                child: const ColoredBox(color: Colors.green),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('iOS theme shows Dynamic Island and home indicator', (
    WidgetTester tester,
  ) async {
    await pumpFrame(tester, platform: TargetPlatform.iOS);

    expect(
      find.byKey(const ValueKey<String>('onboarding_iphone_dynamic_island')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('onboarding_ios_home_indicator')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('onboarding_samsung_hole_punch')),
      findsNothing,
    );
  });

  testWidgets('Android theme shows Samsung hole-punch', (
    WidgetTester tester,
  ) async {
    await pumpFrame(tester, platform: TargetPlatform.android);

    expect(
      find.byKey(const ValueKey<String>('onboarding_samsung_hole_punch')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('onboarding_iphone_dynamic_island')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('onboarding_ios_home_indicator')),
      findsNothing,
    );
  });

  testWidgets('platformOverride forces iOS chrome on Android theme', (
    WidgetTester tester,
  ) async {
    await pumpFrame(
      tester,
      platform: TargetPlatform.android,
      platformOverride: TargetPlatform.iOS,
    );

    expect(
      find.byKey(const ValueKey<String>('onboarding_iphone_dynamic_island')),
      findsOneWidget,
    );
  });
}
