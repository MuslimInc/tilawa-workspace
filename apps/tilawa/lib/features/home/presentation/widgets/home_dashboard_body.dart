import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/widgets/deferred_after_first_frame.dart';
import 'package:tilawa/features/today_plan/today_plan.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../cubit/home_listening_resume_cubit.dart';
import '../cubit/home_listening_resume_state.dart';
import '../cubit/home_primary_action_cubit.dart';
import '../cubit/home_primary_action_state.dart';
import 'home_daily_inspiration_section.dart';
import 'home_discover_shortcuts.dart';
import 'home_listening_resume_row.dart';
import 'home_more_actions_group.dart';
import 'home_primary_action_zone.dart';
import 'home_today_section.dart';

/// Home body — primary action, practice, inspiration, discover, more,
/// listening.
///
/// IA zones (top → bottom):
/// 1. **Now** — hero (prayer, greeting, location) — owned by sliver above.
/// 2. **Primary action** — resume card (Quran / listening / urgent athkar).
///    Always surfaces the Quran reader entry — comfortable reach.
/// 3. **Practice** — optional Today Plan + daily athkar (pinned + edit).
/// 4. **Inspiration** — daily ayah and dua in one raised card.
/// 5. **Discover shortcuts** — compact 2-col grid of supporting tools
///    (Reciters, Qibla, Tasbeeh, Bookmarks, Sessions).
/// 6. **More** — secondary destinations as a flat grouped list (History,
///    Favorites, Downloads, Smart Khatma, Support).
/// 7. **Listening resume** — conditional continue-listening row.
///
/// **Spacing rhythm** (relationship-based):
/// - Within same zone: `spaceLarge` (16 dp).
/// - Between zones: `spaceExtraLarge + spaceSmall` (32 dp) for unrelated
///   zones; `spaceExtraLarge` (24 dp) for related secondary zones.
class HomeDashboardBody extends StatelessWidget {
  const HomeDashboardBody({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    // Zone gap — 2× the within-zone spacing for clear IA separation.
    final double zoneGap = tokens.spaceExtraLarge + tokens.spaceSmall;
    // Within-zone gap — tighter grouping for related content.
    final double withinZoneGap = tokens.spaceLarge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomePrimaryActionZone(),
        DeferredAfterFirstFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Primary action → Practice: same ritual zone (tight).
              SizedBox(height: withinZoneGap),
              if (isTodayPlanEnabled()) ...[
                const TodayPlanCard(),
                SizedBox(height: withinZoneGap),
              ],
              const HomeDailyPracticeSection(),
              // Practice → Inspiration: new zone (wide).
              SizedBox(height: zoneGap),
              const HomeDailyInspirationSection(),
              // Inspiration → Discover: new zone (wide).
              SizedBox(height: zoneGap),
              const HomeDiscoverShortcuts(),
              // Discover → More: related secondary content.
              SizedBox(height: tokens.spaceExtraLarge),
              const HomeMoreActionsGroup(),
              // The listening row owns its own leading gap so a hidden row
              // leaves no dangling space.
              const _ConditionalListeningRow(),
              // Closing mark — Peak-End Rule ending moment.
              const _HomeDashboardClosingMark(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConditionalListeningRow extends StatelessWidget {
  const _ConditionalListeningRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomePrimaryActionCubit, HomePrimaryActionState>(
      builder: (context, primaryState) {
        // The primary action card already surfaces the listening resume.
        if (primaryState.kind == HomePrimaryActionKind.listening) {
          return const SizedBox.shrink();
        }
        return BlocBuilder<HomeListeningResumeCubit, HomeListeningResumeState>(
          builder: (context, listeningState) {
            if (!listeningState.isVisible) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: context.tokens.spaceExtraLarge),
                const HomeListeningResumeRow(),
              ],
            );
          },
        );
      },
    );
  }
}

/// Calm ending watermark at the bottom of the home dashboard.
///
/// Peak-End Rule: the ending matters. This provides gentle closure
/// instead of the page just "falling off." Extremely quiet — does not
/// compete with content.
class _HomeDashboardClosingMark extends StatelessWidget {
  const _HomeDashboardClosingMark();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final Color markColor = theme.colorScheme.onSurfaceVariant.withValues(
      alpha: 0.35,
    );

    return Padding(
      padding: EdgeInsets.only(
        top: tokens.spaceExtraLarge + tokens.spaceMedium,
        bottom: tokens.spaceMedium,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.spaceExtraSmall,
          children: [
            TilawaIcons.quran.svg(
              size: tokens.iconSizeSmall,
              color: markColor,
            ),
            Text(
              context.l10n.appTitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: markColor,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
