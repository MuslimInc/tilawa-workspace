import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/presentation/theme/quran_sessions_palette.dart';
import 'package:quran_sessions/src/presentation/theme/quran_sessions_theme.dart';
import 'package:quran_sessions/src/presentation/theme/quran_sessions_theme_scope.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('QuranSessionsTheme', () {
    test('fromTheme derives colors from app ColorScheme', () {
      final appTheme = AppTheme.getLightTheme(
        primaryColor: AppColors.primarySage,
      );
      final feature = QuranSessionsTheme.fromTheme(appTheme);
      final palette = QuranSessionsPalette.fromScheme(appTheme.colorScheme);

      expect(feature.primaryColor, palette.primary);
      expect(feature.ratingColor, palette.rating);
      expect(feature.linkColor, appTheme.colorScheme.primary);
      expect(feature.destructive, appTheme.colorScheme.error);
      expect(feature.disabledBackground, palette.disabledBackground);
      expect(feature.joinAvailable, appTheme.colorScheme.primary);
    });

    testWidgets('scope keeps parent ColorScheme and adds feature extension', (
      tester,
    ) async {
      final appTheme = AppTheme.getLightTheme(
        primaryColor: AppColors.primarySage,
      );
      late QuranSessionsTheme resolved;
      late ThemeData parentTheme;

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: Builder(
            builder: (context) {
              parentTheme = Theme.of(context);
              return QuranSessionsThemeScope(
                child: Builder(
                  builder: (context) {
                    resolved = QuranSessionsTheme.of(context);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(parentTheme.colorScheme.primary, AppColors.primarySage);
      expect(resolved.primaryColor, AppColors.primarySage);
      expect(
        Theme.of(
          tester.element(find.byType(SizedBox)),
        ).colorScheme.primary,
        AppColors.primarySage,
      );
    });
  });
}
