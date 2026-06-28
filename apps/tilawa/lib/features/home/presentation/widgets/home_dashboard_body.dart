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
import 'home_primary_actions_section.dart';
import 'home_quick_tools_section.dart';

/// Home body — product-grade hierarchy under the Sliver Prayer Hero.
///
/// IA zones (top → bottom):
/// 1. **Now** — Sliver Prayer Hero (location, Hijri date, next prayer) — sliver above.
/// 2. **Primary actions** — Quran Reader, Athkar (two large cards).
/// 3. **Quick tools** — Reciters, Qibla, Tasbeeh (compact row).
/// 4. **Today Plan** — optional daily worship plan card.
/// 5. **Continue** — conditional continue-listening row.
/// 6. **More** — secondary library/account destinations.
/// 7. **Inspiration** — passive daily ayah and dua at the bottom.
///
/// The featured tutor card is a scroll-away sliver directly under the hero.
///
/// Hierarchy: primary cards > quick tools > more list.
///
/// **Spacing rhythm** (relationship-based):
/// - Within same zone: `spaceLarge` rhythm.
/// - Between zones: `spaceExtraLarge` for unrelated zones; `spaceLarge` for
///   related secondary zones.
class HomeDashboardBody extends StatelessWidget {
  const HomeDashboardBody({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final double zoneGap = tokens.spaceExtraLarge;
    final double sectionGap = tokens.spaceLarge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomePrimaryActionsSection(),
        SizedBox(height: sectionGap),
        const HomeQuickToolsSection(),
        DeferredAfterFirstFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: zoneGap),
              if (isTodayPlanEnabled()) ...[
                const TodayPlanCard(),
                SizedBox(height: tokens.spaceLarge),
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
