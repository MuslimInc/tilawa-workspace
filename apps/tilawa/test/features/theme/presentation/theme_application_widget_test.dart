import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/theme/domain/app_theme_mode.dart';
import 'package:tilawa/features/theme/domain/entities/app_theme_preset.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/features/theme/presentation/cubit/theme_cubit.dart';
import 'package:tilawa/features/theme/presentation/theme_state_material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _ThemeProbe extends StatelessWidget {
  const _ThemeProbe();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      '${theme.colorScheme.primary.toARGB32()},'
      '${theme.scaffoldBackgroundColor.toARGB32()},'
      '${theme.tokens.spaceMedium}',
      key: const Key('theme_probe'),
    );
  }
}

Widget _themedApp({
  required ThemeState state,
  required Widget child,
}) {
  return MaterialApp(
    theme: AppTheme.getLightTheme(primaryColor: state.primaryColor),
    darkTheme: AppTheme.getDarkTheme(
      primaryColor: state.primaryColor,
      isDefaultPreset:
          state.primaryColorSource == PrimaryColorSource.preset &&
          state.primaryPresetId == PrimaryColorPreset.defaultPreset.id,
      darkIsTrueBlack: state.preset == AppThemePreset.trueBlack,
    ),
    themeMode: state.themeMode,
    home: Scaffold(body: child),
  );
}

void main() {
  group('theme application widget', () {
    testWidgets('light theme exposes tokens and parchment scaffold', (
      WidgetTester tester,
    ) async {
      const state = ThemeState(mode: AppThemeMode.light);

      await tester.pumpWidget(
        _themedApp(
          state: state,
          child: const _ThemeProbe(),
        ),
      );

      final context = tester.element(find.byKey(const Key('theme_probe')));
      final theme = Theme.of(context);

      expect(theme.extension<MeMuslimDesignTokens>(), isNotNull);
      expect(theme.extension<MeMuslimComponentTokens>(), isNotNull);
      expect(theme.scaffoldBackgroundColor, AppColors.lightCanvas);
      expect(theme.tokens.spaceMedium, 12.0);
    });

    testWidgets('dark ThemeState applies dark color scheme', (
      WidgetTester tester,
    ) async {
      const state = ThemeState(mode: AppThemeMode.dark);

      await tester.pumpWidget(
        _themedApp(
          state: state,
          child: const _ThemeProbe(),
        ),
      );

      final context = tester.element(find.byKey(const Key('theme_probe')));
      expect(
        Theme.of(context).colorScheme.brightness,
        Brightness.dark,
      );
    });

    testWidgets('trueBlack preset uses black scaffold in dark mode', (
      WidgetTester tester,
    ) async {
      const state = ThemeState(
        mode: AppThemeMode.dark,
        preset: AppThemePreset.trueBlack,
      );

      await tester.pumpWidget(
        _themedApp(
          state: state,
          child: const _ThemeProbe(),
        ),
      );

      final context = tester.element(find.byKey(const Key('theme_probe')));
      expect(Theme.of(context).scaffoldBackgroundColor, Colors.black);
    });
  });
}
