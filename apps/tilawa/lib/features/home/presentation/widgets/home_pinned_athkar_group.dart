import 'package:flutter/material.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_category.dart';
import 'package:tilawa/features/athkar/presentation/athkar_category_presentation.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_dashboard_card.dart';
import 'home_grouped_list_row.dart';

/// Pinned athkar shortcuts in one raised card — same rhythm as [HomeMoreActionsGroup].
class HomePinnedAthkarGroup extends StatelessWidget {
  const HomePinnedAthkarGroup({
    super.key,
    required this.categories,
    this.onLongPressCategory,
  });

  final List<AthkarCategory> categories;
  final ValueChanged<AthkarCategory>? onLongPressCategory;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final tokens = Theme.of(context).tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final product = Theme.of(context).productColors;
    final Color dividerColor = colorScheme.outlineVariant;

    // Four distinct icon colour pairs cycling through the available palette.
    final List<(Color bg, Color fg)> tints = [
      (colorScheme.primary.withValues(alpha: 0.13), colorScheme.primary),
      (
        product.featuredGradientStart.withValues(alpha: 0.28),
        product.featuredGradientEnd,
      ),
      (colorScheme.success.withValues(alpha: 0.14), colorScheme.success),
      (colorScheme.primary.withValues(alpha: 0.08), colorScheme.tertiary),
    ];

    return HomeDashboardCard(
      surface: TilawaCardSurface.flat,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < categories.length; i++) ...[
            if (i > 0)
              TilawaDivider(
                height: tokens.borderWidthThin,
                color: dividerColor,
              ),
            _PinnedAthkarGroupRow(
              category: categories[i],
              iconBackgroundColor: tints[i % tints.length].$1,
              iconColor: tints[i % tints.length].$2,
              onLongPress: onLongPressCategory == null
                  ? null
                  : () => onLongPressCategory!(categories[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _PinnedAthkarGroupRow extends StatelessWidget {
  const _PinnedAthkarGroupRow({
    required this.category,
    required this.iconBackgroundColor,
    required this.iconColor,
    this.onLongPress,
  });

  final AthkarCategory category;
  final Color iconBackgroundColor;
  final Color iconColor;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final String title = localizedAthkarCategoryTitle(context, category);

    return HomeGroupedListRow(
      icon: athkarCategoryIcon(category.icon),
      iconBackgroundColor: iconBackgroundColor,
      iconColor: iconColor,
      title: title,
      onTap: () {
        AthkarDetailsRoute(
          categoryId: category.id,
          categoryName: title,
          source: 'home_pinned_row',
        ).push(context);
      },
      onLongPress: onLongPress,
      semanticLabel: title,
    );
  }
}
