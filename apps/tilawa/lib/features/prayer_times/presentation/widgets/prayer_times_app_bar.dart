import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../prayer_notification_semantics_ids.dart';

/// Height of the today / monthly tab row in [PrayerTimesAppBar.bottom].
///
/// Matches the reciters catalog tab strip:
/// [TilawaAppBarConfig.catalogChromePadding] + [kTextTabBarHeight].
double prayerTimesAppBarBottomExtent(BuildContext context) {
  final TilawaDesignTokens tokens = Theme.of(context).tokens;
  return TilawaAppBarConfig.catalogChromePadding(tokens).vertical +
      kTextTabBarHeight;
}

/// [RefreshIndicator.edgeOffset] below the pinned prayer-times header.
double prayerTimesRefreshIndicatorEdgeOffset(BuildContext context) {
  return MediaQuery.paddingOf(context).top +
      kToolbarHeight +
      prayerTimesAppBarBottomExtent(context);
}

/// Pinned title, settings action, and today / monthly segments.
///
/// Use inside [NestedScrollView.headerSliverBuilder] wrapped with
/// [SliverOverlapAbsorber] so tab bodies can inject overlap.
class PrayerTimesAppBar extends StatelessWidget {
  const PrayerTimesAppBar({
    super.key,
    required this.tabController,
    required this.onSegmentChanged,
    required this.onSettingsTap,
  });

  final TabController tabController;
  final ValueChanged<String> onSegmentChanged;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final TilawaDesignTokens tokens = Theme.of(context).tokens;

    return TilawaSliverAppBar(
      surface: TilawaAppBarSurface.parchment,
      automaticallyImplyLeading: false,
      centerTitle: false,
      title: context.l10n.prayerTimes,
      actions: [
        Semantics(
          identifier: PrayerNotificationSemanticsIds.prayerSettingsButton,
          child: TilawaIconActionButton(
            icon: Icons.settings,
            onTap: onSettingsTap,
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(prayerTimesAppBarBottomExtent(context)),
        child: Padding(
          padding: TilawaAppBarConfig.catalogChromePadding(tokens),
          child: _PrayerTimesHomeTabBar(
            controller: tabController,
            onSegmentChanged: onSegmentChanged,
          ),
        ),
      ),
    );
  }
}

/// Catalog-style tab strip — same chrome as reciters (All / Favorites / Downloads).
class _PrayerTimesHomeTabBar extends StatelessWidget {
  const _PrayerTimesHomeTabBar({
    required this.controller,
    required this.onSegmentChanged,
  });

  final TabController controller;
  final ValueChanged<String> onSegmentChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final chipTokens = theme.componentTokens.chip;

    return SizedBox(
      height: kTextTabBarHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
        ),
        child: TabBar(
          controller: controller,
          onTap: (int index) {
            onSegmentChanged(index == 0 ? 'today' : 'monthly');
          },
          splashBorderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: EdgeInsets.all(tokens.spaceExtraSmall),
          indicator: BoxDecoration(
            color: colorScheme.onSurface,
            borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
          ),
          labelColor: colorScheme.surface,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: chipTokens.selectionFontWeight,
          ),
          unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            _PrayerTimesTab(label: context.l10n.today),
            _PrayerTimesTab(label: context.l10n.monthly),
          ],
        ),
      ),
    );
  }
}

class _PrayerTimesTab extends StatelessWidget {
  const _PrayerTimesTab({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: kTextTabBarHeight,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Maps swipe progress to the nearest segment so the control updates mid-gesture.
@visibleForTesting
int segmentIndexForTabPage(double page, int length) {
  return page.round().clamp(0, length - 1);
}
