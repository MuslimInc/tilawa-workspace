import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/athkar/presentation/widgets/pinned_athkar_home_section.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_dashboard_section.dart';
import 'home_prayer_carousel.dart';
import 'home_quran_entry_grid.dart';
import 'home_sessions_entry_card.dart';

/// Home body — three focused sections below the prayer-time hero:
///
///   1. Quran entry  — Reciters tab + Quran image reader
///   2. Quick athkar — user-pinned athkar categories
///   3. Prayer link  — compact anchor to the full prayer-times screen
class HomeDashboardBody extends StatelessWidget {
  const HomeDashboardBody({super.key, required this.onOpenPrayer});

  final VoidCallback onOpenPrayer;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section 1 — Quran entry points
        HomeDashboardSection(
          title: context.l10n.homeQuickQuran,
          child: const HomeQuranEntryGrid(),
        ),
        SizedBox(height: tokens.spaceLarge),

        // Section 2 — Quick athkar pick
        HomeDashboardSection(
          title: context.l10n.homeAthkarRitualsTitle,
          trailing: _EditPinnedButton(),
          contentSpacing: tokens.spaceSmall,
          child: const PinnedAthkarHomeSection(hideHeader: true),
        ),
        SizedBox(height: tokens.spaceLarge),

        // Section 3 — Quran Sessions entry (experimental feature)
        const HomeSessionsEntryCard(),
        SizedBox(height: tokens.spaceLarge),

        // Section 4 — Prayer times carousel (bleeds edge-to-edge via OverflowBox)
        HomeDashboardSection(
          title: context.l10n.homePrayerTimesAction,
          child: HomePrayerCarousel(onOpenPrayer: onOpenPrayer),
        ),
        SizedBox(height: tokens.spaceMedium),
      ],
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
