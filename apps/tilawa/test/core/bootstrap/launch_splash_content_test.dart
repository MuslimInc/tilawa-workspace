import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/launch_splash_content.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('LaunchSplashContent', () {
    testWidgets('renders logo at launchSplashLogoFrameSize', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: AppColors.launchSplashBackground,
            body: Center(
              child: LaunchSplashContent(source: 'test'),
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      final Size logoBox = tester.getSize(
        find.ancestor(
          of: find.byType(Image),
          matching: find.byType(SizedBox),
        ),
      );
      expect(logoBox.width, AppColors.launchSplashLogoFrameSize);
      expect(logoBox.height, AppColors.launchSplashLogoFrameSize);
    });

    testWidgets('animates logo once and holds the final frame', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: AppColors.launchSplashBackground,
            body: Center(
              child: LaunchSplashContent(source: 'test'),
            ),
          ),
        ),
      );

      final ScaleTransition initialScale = tester.widget<ScaleTransition>(
        find.byKey(LaunchSplashContent.logoScaleKey),
      );
      final FadeTransition initialOpacity = tester.widget<FadeTransition>(
        find.byKey(LaunchSplashContent.logoOpacityKey),
      );

      expect(initialScale.scale.value, lessThan(1));
      expect(initialOpacity.opacity.value, 0);

      await tester.pump(LaunchSplashContent.iconAnimationDuration);

      final ScaleTransition finalScale = tester.widget<ScaleTransition>(
        find.byKey(LaunchSplashContent.logoScaleKey),
      );
      final FadeTransition finalOpacity = tester.widget<FadeTransition>(
        find.byKey(LaunchSplashContent.logoOpacityKey),
      );

      expect(finalScale.scale.value, 1);
      expect(finalOpacity.opacity.value, 1);

      await tester.pump(const Duration(seconds: 3));

      final ScaleTransition heldScale = tester.widget<ScaleTransition>(
        find.byKey(LaunchSplashContent.logoScaleKey),
      );
      expect(heldScale.scale.value, 1);
    });

    testWidgets('shows wordmark and delayed progress when configured', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: AppColors.launchSplashBackground,
            body: Center(
              child: LaunchSplashContent(
                source: 'test',
                wordmark: 'MeMuslim',
                showProgress: true,
                progressDelay: Duration(milliseconds: 100),
              ),
            ),
          ),
        ),
      );

      expect(find.text('MeMuslim'), findsOneWidget);
      expect(find.byKey(const Key('launch_splash_progress')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump();

      expect(
        tester
            .widget<AnimatedOpacity>(
              find.ancestor(
                of: find.byKey(const Key('launch_splash_progress')),
                matching: find.byType(AnimatedOpacity),
              ),
            )
            .opacity,
        1,
      );
    });
  });
}
