import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/layout/home_dashboard_scroll_padding.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('homeDashboardScrollBottomPadding', () {
    late MeMuslimDesignTokens tokens;

    setUp(() {
      tokens = MeMuslimDesignTokens.light();
    });

    test('content gap is 16 dp via spaceLarge token', () {
      expect(tokens.spaceLarge, 16);
    });

    testWidgets(
      'returns 16 dp when hosted in TilawaShellPadding without player',
      (
        tester,
      ) async {
        late double padding;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.getLightTheme(
              primaryColor: AppColors.defaultPrimary,
            ),
            home: TilawaShellPadding(
              padding: 0,
              child: Builder(
                builder: (context) {
                  padding = homeDashboardScrollBottomPadding(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        expect(padding, tokens.spaceLarge);
      },
    );

    testWidgets('returns 16 dp when hosted in TilawaShellPadding with player', (
      tester,
    ) async {
      late double padding;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(
            primaryColor: AppColors.defaultPrimary,
          ),
          home: TilawaShellPadding(
            padding: 57,
            child: Builder(
              builder: (context) {
                padding = homeDashboardScrollBottomPadding(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(padding, tokens.spaceLarge);
    });

    testWidgets('returns 16 dp when shell padding host is absent', (
      tester,
    ) async {
      late double padding;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(
            primaryColor: AppColors.defaultPrimary,
          ),
          home: Builder(
            builder: (context) {
              padding = homeDashboardScrollBottomPadding(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(padding, tokens.spaceLarge);
    });

    testWidgets('player height does not change bottom padding', (tester) async {
      const double miniPlayerHeight = 57;
      late double paddingWithoutPlayer;
      late double paddingWithPlayer;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(
            primaryColor: AppColors.defaultPrimary,
          ),
          home: Column(
            children: [
              TilawaShellPadding(
                padding: 0,
                child: Builder(
                  builder: (context) {
                    paddingWithoutPlayer = homeDashboardScrollBottomPadding(
                      context,
                    );
                    return const SizedBox.shrink();
                  },
                ),
              ),
              TilawaShellPadding(
                padding: miniPlayerHeight,
                child: Builder(
                  builder: (context) {
                    paddingWithPlayer = homeDashboardScrollBottomPadding(
                      context,
                    );
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      );

      expect(paddingWithoutPlayer, tokens.spaceLarge);
      expect(paddingWithPlayer, tokens.spaceLarge);
      expect(paddingWithPlayer, paddingWithoutPlayer);
    });
  });
}
