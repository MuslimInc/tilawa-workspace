import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_category.dart';
import 'package:tilawa/features/athkar/domain/pinned_athkar_display_order.dart';
import 'package:tilawa/features/athkar/presentation/cubit/pinned_athkar_cubit.dart';
import 'package:tilawa/features/athkar/presentation/cubit/pinned_athkar_state.dart';
import 'package:tilawa/features/athkar/presentation/widgets/pinned_athkar_home_section.dart';
import 'package:tilawa/features/today_plan/today_plan.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/home_layout_mode.dart';
import 'home_dashboard_section.dart';
import 'home_featured_ritual_card.dart';
import 'home_prayer_day_strip.dart';

/// Zone 2 — Today: prayer strip + optional Today Plan.
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
        if (isTodayPlanEnabled()) ...[
          SizedBox(height: tokens.spaceExtraLarge),
          const TodayPlanCard(),
        ],
      ],
    );
  }
}

/// Zone 3 — Your rituals: contextual athkar inline + pinned athkar list/grid.
///
/// The section title row carries the edit shortcut as trailing so there is no
/// nested sub-header. Contextual athkar appears above the pinned list without
/// any extra wrapper label.
class HomeDailyPracticeSection extends StatelessWidget {
  const HomeDailyPracticeSection({
    super.key,
    required this.layoutMode,
  });

  final HomeLayoutMode layoutMode;

  @override
  Widget build(BuildContext context) {
    return HomeDashboardSection(
      title: context.l10n.homeAthkarRitualsTitle,
      trailing: _EditPinnedButton(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ContextualAthkarCard(),
          PinnedAthkarHomeSection(
            hideContextualFeatured: true,
            hideHeader: true,
            layoutMode: layoutMode,
          ),
        ],
      ),
    );
  }
}

class _EditPinnedButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TilawaIconActionButton(
      icon: Icons.edit_outlined,
      onTap: () => showPinnedAthkarPicker(context),
      backgroundColor: Colors.transparent,
      tooltip: context.l10n.homePinnedAthkarEdit,
      semanticLabel: context.l10n.homePinnedAthkarEdit,
    );
  }
}

/// Contextual athkar card shown at the top of the Daily Practice section
/// when a time-relevant pinned category exists. Hidden when none match.
class _ContextualAthkarCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return BlocBuilder<PinnedAthkarCubit, PinnedAthkarState>(
      buildWhen: (previous, current) =>
          previous.pinnedCategories != current.pinnedCategories ||
          previous.status != current.status,
      builder: (context, state) {
        if (state.status != PinnedAthkarStatus.ready ||
            state.pinnedCategories.isEmpty) {
          return const SizedBox.shrink();
        }

        final now = DateTime.now();
        final AthkarCategory? featured = contextualAthkarCategory(
          categories: orderPinnedAthkarForTime(
            pinned: state.pinnedCategories,
            now: now,
          ),
          now: now,
        );

        if (featured == null) return const SizedBox.shrink();

        return Padding(
          padding: EdgeInsets.only(bottom: tokens.spaceSmall),
          child: HomeFeaturedRitualCard(
            category: featured,
            promptLabel: (title) =>
                context.l10n.homeContextualAthkarPrompt(title),
            nowBadgeLabel: context.l10n.homeAthkarNowBadge,
            startLabel: context.l10n.homeFeaturedRitualStart,
            layout: HomeFeaturedRitualCardLayout.row,
          ),
        );
      },
    );
  }
}
