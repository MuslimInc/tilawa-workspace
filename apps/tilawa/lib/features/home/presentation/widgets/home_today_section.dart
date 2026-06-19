import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/athkar/presentation/widgets/pinned_athkar_home_section.dart';
import 'package:tilawa/features/today_plan/today_plan.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/home_layout_mode.dart';
import 'home_dashboard_section.dart';
import 'home_prayer_day_strip.dart';
import 'home_section_link.dart';
import 'home_today_featured_carousel.dart';

/// Unified daily hub: prayer glance, Mushaf resume, rituals, and plans.
class HomeTodaySection extends StatelessWidget {
  const HomeTodaySection({
    super.key,
    required this.onOpenPrayer,
    required this.layoutMode,
  });

  final VoidCallback onOpenPrayer;
  final HomeLayoutMode layoutMode;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeDashboardSection(
          title: context.l10n.homeTodayTitle,
          subtitle: context.l10n.homeTodaySubtitle,
          child: HomePrayerDayStrip(onOpenPrayer: onOpenPrayer),
        ),
        SizedBox(height: tokens.spaceLarge),
        HomeDashboardSubsectionHeader(
          title: context.l10n.homeFeaturedTitle,
          trailing: HomeSeeAllLink(
            onPressed: () => const QuranIndexRoute().push(context),
          ),
        ),
        SizedBox(height: tokens.spaceMedium),
        const HomeTodayFeaturedCarousel(),
        SizedBox(height: tokens.spaceLarge),
        PinnedAthkarHomeSection(
          hideContextualFeatured: true,
          layoutMode: layoutMode,
        ),
        if (isTodayPlanEnabled()) ...[
          SizedBox(height: tokens.spaceLarge),
          const TodayPlanCard(),
        ],
      ],
    );
  }
}
