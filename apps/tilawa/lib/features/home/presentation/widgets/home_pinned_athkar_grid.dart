import 'package:flutter/material.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_category.dart';
import 'package:tilawa/features/athkar/presentation/athkar_category_presentation.dart';
import 'package:tilawa/features/athkar/presentation/widgets/athkar_category_card.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_dashboard_shortcut_grid.dart';

/// Pinned athkar shortcuts as a responsive card grid.
class HomePinnedAthkarGrid extends StatelessWidget {
  const HomePinnedAthkarGrid({
    super.key,
    required this.categories,
  });

  final List<AthkarCategory> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return HomeDashboardShortcutGrid(
      columnCount: 2,
      tileHeight: _athkarGridTileHeight(context),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final AthkarCategory category = categories[index];
        final String title = localizedAthkarCategoryTitle(context, category);
        return AthkarCategoryCard(
          name: title,
          icon: category.icon,
          onTap: () {
            AthkarDetailsRoute(
              categoryId: category.id,
              categoryName: title,
              source: 'home_pinned_grid',
            ).push(context);
          },
        );
      },
    );
  }
}

double _athkarGridTileHeight(BuildContext context) {
  final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
  final TextTheme textTheme = Theme.of(context).textTheme;
  final double iconExtent = tokens.iconHubExtent;
  final double titleLineHeight = (textTheme.titleMedium?.fontSize ?? 16) * 1.25;
  final double textBlockHeight = titleLineHeight * 2;
  return tokens.spaceLarge * 2 +
      iconExtent +
      tokens.spaceMedium +
      textBlockHeight;
}
