import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../cubit/home_layout_cubit.dart';
import '../cubit/home_layout_state.dart';
import '../../domain/entities/home_layout_mode.dart';
import 'home_adaptive_shortcuts.dart';
import 'home_layout_toggle_button.dart';
import 'home_daily_inspiration_section.dart';
import 'home_more_actions_group.dart';
import 'home_shortcut_entry.dart';
import 'home_today_section.dart';

/// Scrollable Home body below the hero, organized by UX attention zones.
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
            HomeTodaySection(onOpenPrayer: onOpenPrayer),
            SizedBox(height: tokens.spaceExtraLarge),
            _HomeDashboardSection(
              title: context.l10n.homeDailyInspirationTitle,
              subtitle: context.l10n.homeDailyInspirationSubtitle,
              child: const HomeDailyInspirationSection(),
            ),
            SizedBox(height: tokens.spaceExtraLarge),
            _HomeDashboardSection(
              title: context.l10n.homeExploreTitle,
              trailing: const HomeLayoutToggleButton(),
              child: _HomeMoreActions(
                layoutMode: layoutState.mode,
                onOpenReciters: onOpenReciters,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Shared title → subtitle → content rhythm for Home dashboard zones.
class _HomeDashboardSection extends StatelessWidget {
  const _HomeDashboardSection({
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: TilawaSectionTitle(title: title)),
            ?trailing,
          ],
        ),
        if (subtitle != null) ...[
          SizedBox(height: tokens.spaceExtraSmall),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        SizedBox(height: tokens.spaceMedium),
        child,
      ],
    );
  }
}

class _HomeMoreActions extends StatelessWidget {
  const _HomeMoreActions({
    required this.layoutMode,
    required this.onOpenReciters,
  });

  final HomeLayoutMode layoutMode;
  final VoidCallback onOpenReciters;

  @override
  Widget build(BuildContext context) {
    final entries = [
      HomeShortcutEntry(
        icon: FluentIcons.person_voice_24_regular,
        title: context.l10n.homeQuickReciters,
        subtitle: context.l10n.homeQuickRecitersSubtitle,
        onTap: onOpenReciters,
      ),
      HomeShortcutEntry(
        icon: FluentIcons.circle_hint_24_regular,
        title: context.l10n.homeQuickTasbeeh,
        subtitle: context.l10n.homeQuickTasbeehSubtitle,
        onTap: () => const TasbeehRoute().push(context),
      ),
      HomeShortcutEntry(
        icon: FluentIcons.compass_northwest_24_regular,
        title: context.l10n.homeQuickQibla,
        subtitle: context.l10n.homeQuickQiblaSubtitle,
        onTap: () => const QiblaRoute().push(context),
      ),
    ];

    return HomeAdaptiveShortcuts(
      layoutMode: layoutMode,
      gridColumnCount: 2,
      gridEntries: entries,
      listChild: HomeMoreActionsGroup(
        actions: [
          for (final HomeShortcutEntry entry in entries)
            HomeMoreAction(
              label: entry.title,
              subtitle: entry.subtitle,
              icon: entry.icon,
              onTap: entry.onTap,
            ),
        ],
      ),
    );
  }
}
