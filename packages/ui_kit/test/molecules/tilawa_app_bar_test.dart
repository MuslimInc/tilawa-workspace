import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/foundation/app_colors.dart';
import 'package:tilawa_ui_kit/src/foundation/app_theme.dart';
import 'package:tilawa_ui_kit/src/foundation/design_tokens.dart';
import 'package:tilawa_ui_kit/src/molecules/tilawa_app_bar_config.dart';

ThemeData _lightTheme() => AppTheme.getLightTheme(
  primaryColor: AppColors.defaultPrimary,
  useGoogleFontsOverride: false,
);

void main() {
  group('TilawaAppBarChrome.toolbarControlBackground', () {
    test('vellum enabled uses surface', () {
      final scheme = _lightTheme().colorScheme;
      expect(
        TilawaAppBarChrome.toolbarControlBackground(
          scheme,
          TilawaAppBarSurface.vellum,
          enabled: true,
        ),
        scheme.surface,
      );
    });

    test('parchment enabled uses surfaceContainerHigh', () {
      final scheme = _lightTheme().colorScheme;
      expect(
        TilawaAppBarChrome.toolbarControlBackground(
          scheme,
          TilawaAppBarSurface.parchment,
          enabled: true,
        ),
        scheme.surfaceContainerHigh,
      );
    });

    test('disabled returns transparent', () {
      final scheme = _lightTheme().colorScheme;
      expect(
        TilawaAppBarChrome.toolbarControlBackground(
          scheme,
          TilawaAppBarSurface.vellum,
          enabled: false,
        ),
        Colors.transparent,
      );
    });
  });

  group('TilawaAppBarConfig defaults', () {
    test('elevation shadow is off; hairline is on', () {
      expect(TilawaAppBarConfig.showElevationShadow, isFalse);
      expect(TilawaAppBarConfig.showBottomHairline, isTrue);
      expect(TilawaAppBarConfig.elevation, 1);
    });
  });

  group('TilawaAppBarChrome elevation shadow', () {
    test('enabled uses scheme.shadow at opacityShadow', () {
      final theme = _lightTheme();
      final scheme = theme.colorScheme;
      final tokens = theme.extension<TilawaDesignTokens>()!;
      expect(
        TilawaAppBarChrome.elevationShadowColor(scheme, tokens),
        scheme.shadow.withValues(alpha: tokens.opacityShadow),
      );
    });

    test('bottom hairline uses softened outlineVariant', () {
      final theme = _lightTheme();
      final scheme = theme.colorScheme;
      final tokens = theme.extension<TilawaDesignTokens>()!;
      final RoundedRectangleBorder shape = TilawaAppBarChrome.bottomHairline(
        scheme,
        tokens,
      ) as RoundedRectangleBorder;
      expect(
        shape.side.color,
        scheme.outlineVariant.withValues(alpha: tokens.opacitySubtle * 2.5),
      );
      expect(shape.side.width, tokens.borderWidthThin);
    });

    test('disabled returns transparent shadow and zero elevation', () {
      final theme = _lightTheme();
      final scheme = theme.colorScheme;
      final tokens = theme.extension<TilawaDesignTokens>()!;
      expect(
        TilawaAppBarChrome.elevationShadowColor(
          scheme,
          tokens,
          enabled: false,
        ),
        Colors.transparent,
      );
      expect(TilawaAppBarChrome.elevation(enabled: false), 0);
      expect(TilawaAppBarChrome.scrolledUnderElevation(enabled: false), 0);
    });
  });

  group('TilawaAppBarScope', () {
    testWidgets('leading and action fills respect separate toggles', (
      WidgetTester tester,
    ) async {
      late Color leadingFill;
      late Color actionFill;

      await tester.pumpWidget(
        MaterialApp(
          theme: _lightTheme(),
          home: TilawaAppBarScope(
            surface: TilawaAppBarSurface.vellum,
            showLeadingControlBackground: true,
            showActionControlBackground: false,
            child: Builder(
              builder: (context) {
                final scheme = Theme.of(context).colorScheme;
                final scope = TilawaAppBarScope.maybeOf(context)!;
                leadingFill = scope.leadingControlFillColor(scheme);
                actionFill = scope.actionControlFillColor(scheme);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      final scheme = _lightTheme().colorScheme;
      expect(leadingFill, scheme.surface);
      expect(actionFill, Colors.transparent);
    });
  });
}
