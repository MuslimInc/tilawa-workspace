import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_elevated_surface.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('Home dashboard elevation tiers map to expected shadow depth', (
    tester,
  ) async {
    late ThemeData theme;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        home: Builder(
          key: const Key('elevation_probe'),
          builder: (context) {
            theme = Theme.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final BuildContext context = tester.element(
      find.byKey(const Key('elevation_probe')),
    );
    final Color tint = theme.colorScheme.shadow;
    final tokens = theme.tokens;

    expect(
      HomeDashboardElevatedSurface.shadows(
        context,
        HomeDashboardElevationTier.hero,
      ),
      tokens.elevationFloating(tint),
    );
    expect(
      HomeDashboardElevatedSurface.shadows(
        context,
        HomeDashboardElevationTier.primary,
      ),
      tokens.elevationRaised(tint),
    );
    expect(
      HomeDashboardElevatedSurface.shadows(
        context,
        HomeDashboardElevationTier.quickTool,
      ),
      tokens.elevationSubtle(tint),
    );
    expect(
      HomeDashboardElevatedSurface.shadows(
        context,
        HomeDashboardElevationTier.moreList,
      ),
      isEmpty,
    );
  });
}
