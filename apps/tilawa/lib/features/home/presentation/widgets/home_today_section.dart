import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/athkar/presentation/widgets/pinned_athkar_home_section.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';
import 'package:tilawa/features/today_plan/today_plan.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_prayer_day_strip.dart';
import 'home_quran_resume_card.dart';

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
        SizedBox(height: tokens.spaceMedium),
        const HomeQuranResumeCard(),
        SizedBox(height: tokens.spaceLarge),
        const PinnedAthkarHomeSection(),
        if (isSmartKhatmaEnabled()) ...[
          SizedBox(height: tokens.spaceLarge),
          const SmartKhatmaHomeEntryCard(),
        ],
        if (isTodayPlanEnabled()) ...[
          SizedBox(height: tokens.spaceLarge),
          const TodayPlanCard(),
        ],
      ],
    );
  }
}
