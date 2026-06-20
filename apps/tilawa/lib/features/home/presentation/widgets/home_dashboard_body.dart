import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../cubit/home_layout_cubit.dart';
import '../cubit/home_layout_state.dart';
import '../../domain/entities/home_layout_mode.dart';
import 'home_adaptive_shortcuts.dart';
import 'home_dashboard_section.dart';
import 'home_daily_inspiration_section.dart';
import 'home_layout_toggle_button.dart';
import 'home_more_actions_group.dart';
import 'home_shortcut_entry.dart';
import 'home_quran_resume_card.dart';
import 'home_today_section.dart';

/// Scrollable Home body below the hero, organized into four visual groups:
///
///   1. Quran resume  — gold featured card, no section label
///   2. Today         — prayer strip (overline only) + optional Today Plan
///   3. Your rituals  — contextual athkar + pinned rituals under one title
///   4. Discover      — shortcuts to secondary destinations
///   [unlabelled]     — daily ayah and dua card at the bottom
class HomeDashboardBody extends StatelessWidget {
  const HomeDashboardBody({
    super.key,
    required this.onOpenReciters,
    required this.onOpenPrayer,
    required this.onOpenQibla,
  });

  final VoidCallback onOpenReciters;
  final VoidCallback onOpenPrayer;
  final VoidCallback onOpenQibla;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return BlocBuilder<HomeLayoutCubit, HomeLayoutState>(
      builder: (context, layoutState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Zone 1 — Quran resume (no section title; the card speaks for itself)
            const HomeQuranResumeCard(),
            SizedBox(height: tokens.spaceExtraLarge),

            // Zone 2 — Today
            HomeTodaySection(
              onOpenPrayer: onOpenPrayer,
              layoutMode: layoutState.mode,
            ),
            SizedBox(height: tokens.spaceExtraLarge),

            // Zone 3 — Your rituals
            HomeDailyPracticeSection(layoutMode: layoutState.mode),
            SizedBox(height: tokens.spaceExtraLarge),

            // Zone 4 — Discover
            HomeDashboardSection(
              title: context.l10n.homeExploreTitle,
              trailing: const HomeLayoutToggleButton(),
              child: _DiscoverSection(
                layoutMode: layoutState.mode,
                onOpenReciters: onOpenReciters,
                onOpenQibla: onOpenQibla,
              ),
            ),
            SizedBox(height: tokens.spaceExtraLarge),

            // Unlabelled — daily ayah and dua; the card content is self-evident
            const HomeDailyInspirationSection(),
          ],
        );
      },
    );
  }
}

class _DiscoverSection extends StatelessWidget {
  const _DiscoverSection({
    required this.layoutMode,
    required this.onOpenReciters,
    required this.onOpenQibla,
  });

  final HomeLayoutMode layoutMode;
  final VoidCallback onOpenReciters;
  final VoidCallback onOpenQibla;

  @override
  Widget build(BuildContext context) {
    final entries = _buildEntries(context);

    return HomeAdaptiveShortcuts(
      layoutMode: layoutMode,
      gridColumnCount: 2,
      gridEntries: entries.map((e) => e.shortcut).toList(),
      listChild: HomeMoreActionsGroup(
        actions: [
          for (final _DiscoverEntry entry in entries)
            HomeMoreAction(
              label: entry.shortcut.title,
              subtitle: entry.shortcut.subtitle,
              icon: entry.shortcut.icon,
              iconBackgroundColor: entry.iconBackgroundColor,
              iconColor: entry.iconColor,
              onTap: entry.shortcut.onTap,
              trailing: entry.trailing,
            ),
        ],
      ),
    );
  }

  List<_DiscoverEntry> _buildEntries(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entries = <_DiscoverEntry>[
      _DiscoverEntry(
        iconBackgroundColor: colorScheme.primary.withValues(alpha: 0.13),
        iconColor: colorScheme.primary,
        shortcut: HomeShortcutEntry(
          icon: FluentIcons.person_voice_24_regular,
          title: context.l10n.homeQuickReciters,
          subtitle: context.l10n.homeQuickRecitersSubtitle,
          onTap: onOpenReciters,
        ),
      ),
      _DiscoverEntry(
        iconBackgroundColor: AppColors.featuredGradientStart.withValues(
          alpha: 0.22,
        ),
        iconColor: AppColors.featuredGradientEnd,
        shortcut: HomeShortcutEntry(
          icon: FluentIcons.circle_hint_24_regular,
          title: context.l10n.homeQuickTasbeeh,
          subtitle: context.l10n.homeQuickTasbeehSubtitle,
          onTap: () => const TasbeehRoute().push(context),
        ),
      ),
      _DiscoverEntry(
        iconBackgroundColor: AppColors.success.withValues(alpha: 0.14),
        iconColor: AppColors.success,
        shortcut: HomeShortcutEntry(
          icon: FluentIcons.compass_northwest_24_regular,
          title: context.l10n.homeQuickQibla,
          subtitle: context.l10n.homeQuickQiblaSubtitle,
          onTap: onOpenQibla,
        ),
      ),
      if (isSmartKhatmaEnabled())
        _DiscoverEntry(
          shortcut: HomeShortcutEntry(
            icon: FluentIcons.book_open_24_regular,
            title: context.l10n.khatmaEmptyTitle,
            subtitle: context.l10n.khatmaEmptySubtitle,
            onTap: () => const SmartKhatmaHubRoute().push(context),
          ),
          trailing: TilawaExperimentalBadge(
            label: context.l10n.experimentalBadgeLabel,
          ),
        ),
    ];
    return entries;
  }
}

class _DiscoverEntry {
  const _DiscoverEntry({
    required this.shortcut,
    this.trailing,
    this.iconBackgroundColor,
    this.iconColor,
  });

  final HomeShortcutEntry shortcut;
  final Widget? trailing;
  final Color? iconBackgroundColor;
  final Color? iconColor;
}
