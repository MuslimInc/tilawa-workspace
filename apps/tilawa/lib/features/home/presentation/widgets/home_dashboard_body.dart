import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/widgets/deferred_after_first_frame.dart';
import 'package:tilawa/features/today_plan/today_plan.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../cubit/home_listening_resume_cubit.dart';
import '../cubit/home_listening_resume_state.dart';
import 'home_daily_inspiration_section.dart';
import 'home_listening_resume_row.dart';
import 'home_more_actions_group.dart';
import 'home_quick_actions_section.dart';

/// Home body — quick actions, more, and inspiration.
///
/// IA zones (top → bottom):
/// 1. **Now** — hero (location, Hijri date, next prayer) — sliver above.
/// 2. **Quick actions** — Reciters, Quran reader, Athkar, tutor, Qibla,
///    Tasbeeh (2-column grid).
/// 3. **Today Plan** — optional daily worship plan card.
/// 4. **More** — secondary library/account destinations.
/// 5. **Listening resume** — conditional continue-listening row.
/// 6. **Inspiration** — passive daily ayah and dua at the bottom.
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
    final double withinZoneGap = tokens.spaceLarge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomeQuickActionsSection(),
        DeferredAfterFirstFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: zoneGap),
              if (isTodayPlanEnabled()) ...[
                const TodayPlanCard(),
                SizedBox(height: withinZoneGap),
              ],
              const HomeMoreActionsGroup(),
              const _ConditionalListeningRow(),
              SizedBox(height: zoneGap),
              const HomeDailyInspirationSection(),
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
