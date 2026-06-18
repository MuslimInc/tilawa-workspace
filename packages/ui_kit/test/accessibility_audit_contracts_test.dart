import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/src/atoms/tilawa_error_state.dart';
import '../lib/src/atoms/tilawa_icon_toggle.dart';
import '../lib/src/foundation/color_scheme_ext.dart';
import '../lib/src/foundation/component_tokens/component_tokens_theme.dart';
import '../lib/src/foundation/design_tokens.dart';
import '../lib/src/molecules/tilawa_language_switcher.dart';
import '../lib/src/molecules/tilawa_feedback_strip.dart';
import '../lib/src/molecules/tilawa_permission_banner.dart';
import '../lib/src/molecules/tilawa_selection_tile.dart';
import '../lib/src/organisms/tilawa_media_player_bar.dart';

Widget _themed(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      extensions: [
        TilawaDesignTokens.light(),
        TilawaComponentTokens.light(),
      ],
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

Color _expectedFeedbackBorder(ColorScheme scheme, TilawaFeedbackVariant v) {
  return switch (v) {
    TilawaFeedbackVariant.info => scheme.outline.withValues(alpha: 0.35),
    TilawaFeedbackVariant.success => scheme.success.withValues(alpha: 0.55),
    TilawaFeedbackVariant.warning => scheme.warning.withValues(alpha: 0.55),
    TilawaFeedbackVariant.error => scheme.error.withValues(alpha: 0.72),
  };
}

void main() {
  group('TilawaPermissionBanner', () {
    testWidgets('action TextButton is at least 48×48 dp with semantics', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _themed(
          TilawaPermissionBanner(
            message: 'Location is off',
            actionLabel: 'Open settings',
            onAction: () {},
          ),
        ),
      );

      final buttonFinder = find.widgetWithText(TextButton, 'Open settings');
      final size = tester.getSize(buttonFinder);
      expect(size.width, greaterThanOrEqualTo(kTilawaMinInteractiveDimension));
      expect(size.height, greaterThanOrEqualTo(kTilawaMinInteractiveDimension));

      final sem = tester.getSemantics(buttonFinder);
      expect(sem.flagsCollection.isButton, isTrue);
      expect(sem.label, isNotEmpty);
    });
  });

  group('TilawaMediaPlayerBar', () {
    testWidgets('transport control hit targets are at least 48 dp', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _themed(
          const SizedBox(
            width: 600,
            child: TilawaMediaPlayerBar(
              layoutWidth: 600,
              title: 'Surah',
              subtitle: 'Reciter',
              progress: 0.4,
              isPlaying: false,
              canGoPrevious: true,
              canGoNext: true,
              isSleepTimerEnabled: true,
            ),
          ),
        ),
      );

      final theme = Theme.of(tester.element(find.byType(TilawaMediaPlayerBar)));
      final tokens = theme.componentTokens.mediaPlayerBar;
      expect(
        tokens.controlButtonSize,
        greaterThanOrEqualTo(kTilawaMinInteractiveDimension),
      );
      expect(
        tokens.playPauseButtonSize,
        greaterThanOrEqualTo(kTilawaMinInteractiveDimension),
      );

      final transportButtons = find.descendant(
        of: find.byType(TilawaMediaPlayerBar),
        matching: find.byType(IconButton),
      );
      expect(transportButtons, findsAtLeast(2));

      for (final element in transportButtons.evaluate()) {
        final box = element.renderObject! as RenderBox;
        expect(
          box.size.width,
          greaterThanOrEqualTo(kTilawaMinInteractiveDimension),
        );
        expect(
          box.size.height,
          greaterThanOrEqualTo(kTilawaMinInteractiveDimension),
        );
      }
    });
  });

  group('TilawaIconToggle', () {
    testWidgets('render box is at least 48×48 dp when iconSize is small', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _themed(
          TilawaIconToggle(
            icon: Icons.notifications_outlined,
            activeIcon: Icons.notifications,
            value: false,
            onChanged: (_) {},
            iconSize: 12,
            semanticLabel: 'Notifications',
          ),
        ),
      );

      final box =
          tester.renderObject(find.byType(TilawaIconToggle)) as RenderBox;
      expect(box.hasSize, isTrue);
      expect(box.size.width, greaterThanOrEqualTo(kTilawaMinInteractiveDimension));
      expect(box.size.height, greaterThanOrEqualTo(kTilawaMinInteractiveDimension));

      final sem = tester.getSemantics(find.byType(TilawaIconToggle));
      expect(sem.flagsCollection.isButton, isTrue);
      expect(sem.flagsCollection.isToggled, Tristate.isFalse);
      expect(sem.label, isNotEmpty);
    });
  });

  group('TilawaLanguageSwitcher', () {
    testWidgets('segments expose button + selected semantics with labels', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _themed(
          TilawaLanguageSwitcher(
            currentLanguage: 'en',
            onLanguageChanged: (_) {},
            languages: const ['en', 'ar'],
            getLanguageName: (c) => c == 'en' ? 'English' : 'Arabic',
          ),
        ),
      );

      Future<void> checkSegment(String label, {required bool selected}) async {
        final f = find.ancestor(
          of: find.text(label),
          matching: find.byType(InkWell),
        );
        final sem = tester.getSemantics(f.first);
        expect(sem.flagsCollection.isButton, isTrue);
        if (selected) {
          expect(sem.flagsCollection.isSelected, Tristate.isTrue);
        } else {
          expect(sem.flagsCollection.isSelected, isNot(Tristate.isTrue));
        }
        expect(sem.label, isNotEmpty);
      }

      await checkSegment('English', selected: true);
      await checkSegment('Arabic', selected: false);
    });
  });

  group('TilawaFeedbackStrip', () {
    testWidgets('variants use expected default border colors and live region', (
      WidgetTester tester,
    ) async {
      Future<void> pumpVariant(
        TilawaFeedbackVariant variant,
        String msg,
      ) async {
        await tester.pumpWidget(
          _themed(
            Align(
              alignment: Alignment.topCenter,
              child: TilawaFeedbackStrip(
                variant: variant,
                icon: Icons.info_outline,
                message: msg,
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        );
      }

      for (final variant in TilawaFeedbackVariant.values) {
        final msg = 'msg-${variant.name}';
        await pumpVariant(variant, msg);

        final theme = Theme.of(tester.element(find.text(msg)));
        final expected = _expectedFeedbackBorder(theme.colorScheme, variant);

        final containerFinder = find.ancestor(
          of: find.text(msg),
          matching: find.byType(Container),
        );
        final container = tester.widget<Container>(containerFinder.first);
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.border, isNotNull);
        expect(decoration.border!.top.color, expected);

        final messageSem = tester.getSemantics(find.text(msg));
        expect(messageSem.flagsCollection.isLiveRegion, isTrue);
        expect(messageSem.label, isNotEmpty);
      }
    });
  });

  group('TilawaErrorState', () {
    testWidgets('isRetrying disables retry and shows progress indicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _themed(
          TilawaErrorState(
            icon: Icons.cloud_off,
            title: 'Offline',
            retryLabel: 'Retry',
            onRetry: () {},
            isRetrying: true,
          ),
        ),
      );

      final button = tester.widget<TextButton>(find.byType(TextButton));
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('TilawaSelectionTile', () {
    testWidgets('selected tile exposes Semantics selected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _themed(
          TilawaSelectionTile(
            title: 'Option A',
            isSelected: true,
            onTap: () {},
            showDivider: false,
          ),
        ),
      );

      final inkWell = find.byType(InkWell);
      final sem = tester.getSemantics(inkWell);
      expect(sem.flagsCollection.isSelected, Tristate.isTrue);
      expect(sem.flagsCollection.isButton, isTrue);
      expect(sem.label, isNotEmpty);
      expect(sem.label, contains('Option A'));
    });
  });
}
