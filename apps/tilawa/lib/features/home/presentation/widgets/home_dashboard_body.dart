import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/widgets/deferred_after_first_frame.dart';
import 'package:tilawa/features/today_plan/today_plan.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../cubit/home_listening_resume_cubit.dart';
import '../cubit/home_listening_resume_state.dart';
import 'home_comfort_greeting.dart';
import 'home_daily_inspiration_section.dart';
import 'home_dashboard_body_skeleton.dart';
import 'home_learning_entry.dart';
import 'home_listening_resume_row.dart';
import 'home_more_actions_group.dart';
import 'home_primary_actions_section.dart';
import 'home_quick_tools_section.dart';

/// Home body under the Sliver Prayer Hero — clear sections, no extra chrome.
///
/// Order: greeting → primary worship → urgent Learn → soft Learn →
/// tools → More → listening → inspiration → closing mark.
class HomeDashboardBody extends StatelessWidget {
  const HomeDashboardBody({super.key, this.skeleton = false});

  /// When true (initial dashboard load only), renders
  /// [HomeDashboardBodySkeleton] instead of the live sections. Refreshes on
  /// already-loaded content never set this, so existing content stays put.
  final bool skeleton;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final double zoneGap = tokens.spaceExtraLarge;
    final double sectionGap = tokens.spaceLarge;

    if (skeleton) {
      return const HomeDashboardBodySkeleton();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomeComfortGreeting(),
        SizedBox(height: tokens.spaceMedium),
        const HomePrimaryActionsSection(),
        const HomeLearningUrgentSection(),
        const HomeLearningSoftPrompt(),
        if (isSmartKhatmaEnabled()) ...[
          SizedBox(height: zoneGap),
          const SmartKhatmaHomeEntryCard(),
        ],
        SizedBox(height: sectionGap + tokens.spaceExtraSmall),
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

/// Quiet app mark at the bottom of the home dashboard.
class _HomeDashboardClosingMark extends StatelessWidget {
  const _HomeDashboardClosingMark();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final Color markColor = theme.colorScheme.onSurfaceVariant.withValues(
      alpha: 0.55,
    );

    return Padding(
      padding: EdgeInsets.only(
        top: tokens.spaceExtraLarge,
        bottom: tokens.spaceSmall,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.spaceExtraSmall,
          children: [
            TilawaIcons.quran.svg(
              size: tokens.iconSizeMedium,
              color: markColor,
            ),
            Text(
              context.l10n.appTitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: markColor,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
