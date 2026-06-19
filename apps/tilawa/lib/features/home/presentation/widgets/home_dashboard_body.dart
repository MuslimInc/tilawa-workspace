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
import 'home_today_section.dart';

/// Scrollable Home body below the hero, organized into five clear zones:
///
///   1. Continue  — full-width Quran resume
///   2. Today     — prayer strip + Today Plan (if enabled)
///   3. Daily Practice — contextual athkar + pinned rituals
///   4. Discover  — shortcuts + Smart Khatma (if enabled, badged)
///   5. Inspiration — daily ayah and dua
class HomeDashboardBody extends StatelessWidget {
  const HomeDashboardBody({
    super.key,
    required this.onOpenReciters,
    required this.onOpenPrayer,
  });

  final VoidCallback onOpenReciters;
  final VoidCallback onOpenPrayer;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return BlocBuilder<HomeLayoutCubit, HomeLayoutState>(
      builder: (context, layoutState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Zone 1 — Continue
            const HomeContinueSection(),
            SizedBox(height: tokens.spaceExtraLarge),

            // Zone 2 — Today
            HomeTodaySection(
              onOpenPrayer: onOpenPrayer,
              layoutMode: layoutState.mode,
            ),
            SizedBox(height: tokens.spaceExtraLarge),

            // Zone 3 — Daily Practice
            HomeDailyPracticeSection(layoutMode: layoutState.mode),
            SizedBox(height: tokens.spaceExtraLarge),

            // Zone 4 — Discover
            HomeDashboardSection(
              title: context.l10n.homeExploreTitle,
              subtitle: context.l10n.homeExploreSubtitle,
              trailing: const HomeLayoutToggleButton(),
              child: _DiscoverSection(
                layoutMode: layoutState.mode,
                onOpenReciters: onOpenReciters,
              ),
            ),
            SizedBox(height: tokens.spaceExtraLarge),

            // Zone 5 — Inspiration
            HomeDashboardSection(
              title: context.l10n.homeDailyInspirationTitle,
              subtitle: context.l10n.homeDailyInspirationSubtitle,
              child: const HomeDailyInspirationSection(),
            ),
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
  });

  final HomeLayoutMode layoutMode;
  final VoidCallback onOpenReciters;

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
              onTap: entry.shortcut.onTap,
              trailing: entry.trailing,
            ),
        ],
      ),
    );
  }

  List<_DiscoverEntry> _buildEntries(BuildContext context) {
    final entries = <_DiscoverEntry>[
      _DiscoverEntry(
        shortcut: HomeShortcutEntry(
          icon: FluentIcons.person_voice_24_regular,
          title: context.l10n.homeQuickReciters,
          subtitle: context.l10n.homeQuickRecitersSubtitle,
          onTap: onOpenReciters,
        ),
      ),
      _DiscoverEntry(
        shortcut: HomeShortcutEntry(
          icon: FluentIcons.circle_hint_24_regular,
          title: context.l10n.homeQuickTasbeeh,
          subtitle: context.l10n.homeQuickTasbeehSubtitle,
          onTap: () => const TasbeehRoute().push(context),
        ),
      ),
      _DiscoverEntry(
        shortcut: HomeShortcutEntry(
          icon: FluentIcons.compass_northwest_24_regular,
          title: context.l10n.homeQuickQibla,
          subtitle: context.l10n.homeQuickQiblaSubtitle,
          onTap: () => const QiblaRoute().push(context),
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
  const _DiscoverEntry({required this.shortcut, this.trailing});

  final HomeShortcutEntry shortcut;
  final Widget? trailing;
}
