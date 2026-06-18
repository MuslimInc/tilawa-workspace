import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/athkar/presentation/widgets/pinned_athkar_home_section.dart';
import 'package:tilawa/features/today_plan/today_plan.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_prayer_day_strip.dart';
import 'home_section_link.dart';
import 'home_today_featured_carousel.dart';

/// Unified daily hub: prayer glance, Mushaf resume, rituals, and plans.
class HomeTodaySection extends StatelessWidget {
  const HomeTodaySection({super.key, required this.onOpenPrayer});

  final VoidCallback onOpenPrayer;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TilawaSectionTitle(title: context.l10n.homeTodayTitle),
        SizedBox(height: tokens.spaceExtraSmall),
        Text(
          context.l10n.homeTodaySubtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.spaceMedium),
        HomePrayerDayStrip(onOpenPrayer: onOpenPrayer),
        SizedBox(height: tokens.spaceLarge),
        Row(
          children: [
            Expanded(
              child: TilawaSectionTitle(title: context.l10n.homeFeaturedTitle),
            ),
            HomeSeeAllLink(
              onPressed: () => const QuranIndexRoute().push(context),
            ),
          ],
        ),
        SizedBox(height: tokens.spaceMedium),
        const HomeTodayFeaturedCarousel(),
        SizedBox(height: tokens.spaceLarge),
        const PinnedAthkarHomeSection(hideContextualFeatured: true),
        if (isTodayPlanEnabled()) ...[
          SizedBox(height: tokens.spaceLarge),
          const TodayPlanCard(),
        ],
      ],
    );
  }
}
