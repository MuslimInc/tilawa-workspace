import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/onboarding/presentation/widgets/onboarding_content.dart';
import 'package:tilawa/features/onboarding/presentation/widgets/onboarding_hero_visual.dart';
import 'package:tilawa/features/onboarding/presentation/widgets/onboarding_page.dart';
import 'package:tilawa/features/onboarding/presentation/widgets/onboarding_page_indicator.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  const OnboardingContent content = OnboardingContent(
    imagePath: 'assets/images/listener.png',
    title: 'Quiet minutes\nWith the Quran',
    description: 'Read or listen for a calm start to the day.',
    heroStyle: OnboardingHeroStyle.illustration,
  );

  ThemeData theme() => AppTheme.getLightTheme(
    primaryColor: PrimaryColorPreset.defaultPreset.value,
  );

  Future<void> pumpPage(
    WidgetTester tester, {
    required bool isActive,
    bool disableAnimations = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme(),
        home: MediaQuery(
          data: const MediaQueryData().copyWith(
            disableAnimations: disableAnimations,
          ),
          child: Scaffold(
            body: OnboardingPage(
              content: content,
              semanticsLabel: 'Screen 1 of 3',
              isActive: isActive,
            ),
          ),
        ),
      ),
    );
  }

  group('OnboardingPage entrance', () {
    testWidgets('staggers hero then text on first activation', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, isActive: true);
      // Flush post-frame entrance start, then advance into the stagger window.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));

      final double heroOpacity = tester
          .widget<FadeTransition>(find.byKey(OnboardingPage.heroMotionKey))
          .opacity
          .value;
      final double titleOpacity = tester
          .widget<FadeTransition>(find.byKey(OnboardingPage.titleMotionKey))
          .opacity
          .value;
      final double bodyOpacity = tester
          .widget<FadeTransition>(find.byKey(OnboardingPage.bodyMotionKey))
          .opacity
          .value;

      expect(heroOpacity, greaterThan(0));
      expect(heroOpacity, lessThan(1));
      expect(titleOpacity, lessThan(heroOpacity));
      expect(bodyOpacity, lessThanOrEqualTo(titleOpacity));

      await tester.pump(MeMuslimDesignTokens.light().durationMedium);
      await tester.pump();

      expect(
        tester
            .widget<FadeTransition>(find.byKey(OnboardingPage.heroMotionKey))
            .opacity
            .value,
        1,
      );
      expect(
        tester
            .widget<FadeTransition>(find.byKey(OnboardingPage.titleMotionKey))
            .opacity
            .value,
        1,
      );
      expect(
        tester
            .widget<FadeTransition>(find.byKey(OnboardingPage.bodyMotionKey))
            .opacity
            .value,
        1,
      );
    });

    testWidgets('jumps to final frame when animations are disabled', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, isActive: true, disableAnimations: true);
      await tester.pump();

      expect(
        tester
            .widget<FadeTransition>(find.byKey(OnboardingPage.heroMotionKey))
            .opacity
            .value,
        1,
      );
      expect(
        tester
            .widget<FadeTransition>(find.byKey(OnboardingPage.bodyMotionKey))
            .opacity
            .value,
        1,
      );
    });

    testWidgets('plays entrance only once when reactivated', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme(),
          home: const _ActiveToggleHarness(content: content),
        ),
      );
      await tester.pump();
      await tester.pump(MeMuslimDesignTokens.light().durationMedium);
      await tester.pump();

      await tester.tap(find.byKey(const Key('toggle_active')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('toggle_active')));
      await tester.pump();

      expect(
        tester
            .widget<FadeTransition>(find.byKey(OnboardingPage.heroMotionKey))
            .opacity
            .value,
        1,
      );
    });
  });

  group('OnboardingPageIndicator', () {
    testWidgets('uses zero duration under reduced motion', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme(),
          home: MediaQuery(
            data: const MediaQueryData().copyWith(disableAnimations: true),
            child: const Scaffold(
              body: OnboardingPageIndicator(count: 3, currentIndex: 0),
            ),
          ),
        ),
      );

      final AnimatedContainer first = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .first;
      expect(first.duration, Duration.zero);
    });
  });
}

class _ActiveToggleHarness extends StatefulWidget {
  const _ActiveToggleHarness({required this.content});

  final OnboardingContent content;

  @override
  State<_ActiveToggleHarness> createState() => _ActiveToggleHarnessState();
}

class _ActiveToggleHarnessState extends State<_ActiveToggleHarness> {
  bool _isActive = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          TextButton(
            key: const Key('toggle_active'),
            onPressed: () => setState(() => _isActive = !_isActive),
            child: const Text('toggle'),
          ),
          Expanded(
            child: OnboardingPage(
              content: widget.content,
              semanticsLabel: 'Screen 1 of 3',
              isActive: _isActive,
            ),
          ),
        ],
      ),
    );
  }
}
