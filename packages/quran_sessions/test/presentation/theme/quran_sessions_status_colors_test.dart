import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/presentation/theme/quran_sessions_status_colors.dart';
import 'package:quran_sessions/src/presentation/theme/quran_sessions_theme_scope.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('QuranSessionsStatusColors', () {
    final appTheme = AppTheme.getLightTheme(
      primaryColor: AppColors.primarySage,
    );
    final scheme = appTheme.colorScheme;

    test('fromScheme maps domain status roles to the ColorScheme', () {
      final status = QuranSessionsStatusColors.fromScheme(scheme);

      expect(status.upcoming, scheme.primary);
      expect(status.completed, scheme.tertiary);
      expect(status.cancelled, scheme.error);
      expect(status.cancelledSoft, scheme.errorContainer);
      expect(status.rejected, scheme.error);
      expect(status.missed, scheme.error);
      expect(status.joinAvailable, scheme.primary);
      expect(status.joinUnavailable, scheme.onSurface.withValues(alpha: 0.38));
      expect(status.scheduledBackground, scheme.primaryContainer);
      expect(status.scheduledForeground, scheme.onPrimaryContainer);
      expect(status.rating, scheme.primary);
    });

    testWidgets('scope injects QuranSessionsStatusColors into the subtree', (
      tester,
    ) async {
      late QuranSessionsStatusColors resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: QuranSessionsThemeScope(
            child: Builder(
              builder: (context) {
                resolved = context.quranSessionsStatus;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(resolved.upcoming, AppColors.primarySage);
      expect(resolved.joinAvailable, AppColors.primarySage);
    });

    test('copyWith overrides only the provided field', () {
      final status = QuranSessionsStatusColors.fromScheme(scheme);
      final updated = status.copyWith(missed: const Color(0xFFFFA000));

      expect(updated.missed, const Color(0xFFFFA000));
      expect(updated.cancelled, status.cancelled);
      expect(updated.upcoming, status.upcoming);
    });
  });
}
