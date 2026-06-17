import 'package:flutter/material.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_category.dart';
import 'package:tilawa/features/athkar/presentation/athkar_category_presentation.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_card.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Primary one-tap ritual card for the time-relevant pinned athkar.
class HomeFeaturedRitualCard extends StatelessWidget {
  const HomeFeaturedRitualCard({
    super.key,
    required this.category,
    required this.promptLabel,
    required this.nowBadgeLabel,
    required this.startLabel,
  });

  final AthkarCategory category;
  final String Function(String categoryTitle) promptLabel;
  final String nowBadgeLabel;
  final String startLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final String title = localizedAthkarCategoryTitle(context, category);
    final String prompt = promptLabel(title);

    return Semantics(
      button: true,
      label: prompt,
      child: HomeDashboardCard(
        surface: TilawaCardSurface.raised,
        onTap: () {
          AthkarDetailsRoute(
            categoryId: category.id,
            categoryName: title,
            source: 'home_featured_ritual',
          ).push(context);
        },
        child: Row(
          spacing: tokens.spaceMedium,
          children: [
            TilawaIconBox(
              icon: athkarCategoryIcon(category.icon),
              variant: TilawaIconBoxVariant.tinted,
              backgroundColor: colorScheme.primary,
              iconColor: colorScheme.onPrimary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: tokens.spaceExtraSmall,
                children: [
                  Text(
                    prompt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    startLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              spacing: tokens.spaceExtraSmall,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TilawaStatusChip(
                  label: nowBadgeLabel,
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: tokens.iconSizeSmall,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
