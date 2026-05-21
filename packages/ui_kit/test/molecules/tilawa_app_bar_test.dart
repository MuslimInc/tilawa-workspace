import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/foundation/app_colors.dart';
import 'package:tilawa_ui_kit/src/foundation/app_theme.dart';
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
