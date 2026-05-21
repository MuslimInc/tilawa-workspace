import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../prayer_notification_semantics_ids.dart';

/// Height of the today / monthly segment row in [PrayerTimesAppBar.bottom].
///
/// Matches [TilawaAppBarConfig.searchBottomHeight] used on reciters/bookmarks
/// so the vellum chrome strip has the same vertical rhythm.
double prayerTimesAppBarBottomExtent(BuildContext context) {
  return TilawaAppBarConfig.searchBottomHeight(Theme.of(context));
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
    required this.selectedIndex,
    required this.onSegmentChanged,
    required this.onSettingsTap,
  });

  final int selectedIndex;
  final ValueChanged<String> onSegmentChanged;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;

    return TilawaSliverAppBar(
      automaticallyImplyLeading: false,
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
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceMedium,
            vertical: tokens.spaceMedium,
          ),
          child: TilawaSegmentedControl<String>(
            segments: [
              TilawaSegment(value: 'today', label: context.l10n.today),
              TilawaSegment(value: 'monthly', label: context.l10n.monthly),
            ],
            selectedValue: selectedIndex == 0 ? 'today' : 'monthly',
            backgroundColor: colorScheme.surfaceContainer,
            selectedColor: colorScheme.surface,
            selectedTextColor: colorScheme.primary,
            containerRadius: tokens.resolveRadius(
              family: TilawaRadiusFamily.card,
            ),
            onValueChanged: onSegmentChanged,
          ),
        ),
      ),
    );
  }
}
