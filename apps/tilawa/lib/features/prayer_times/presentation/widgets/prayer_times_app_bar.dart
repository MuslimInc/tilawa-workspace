import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../prayer_notification_semantics_ids.dart';

/// Height of the today / monthly tab row in [PrayerTimesAppBar.bottom].
///
/// Matches the reciters catalog tab strip:
/// [TilawaAppBarConfig.catalogChromePadding] + [kTextTabBarHeight].
double prayerTimesAppBarBottomExtent(BuildContext context) {
  final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
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
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;

    return TilawaSliverAppBar(
      surface: TilawaAppBarSurface.parchment,
      centerTitle: true,
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
          child: TilawaTabBar(
            controller: tabController,
            onTap: (int index) {
              onSegmentChanged(index == 0 ? 'today' : 'monthly');
            },
            tabs: [
              Tab(
                height: kTextTabBarHeight,
                child: Text(
                  context.l10n.today,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Tab(
                height: kTextTabBarHeight,
                child: Text(
                  context.l10n.monthly,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Maps swipe progress to the nearest segment so the control updates mid-gesture.
@visibleForTesting
int segmentIndexForTabPage(double page, int length) {
  return page.round().clamp(0, length - 1);
}
