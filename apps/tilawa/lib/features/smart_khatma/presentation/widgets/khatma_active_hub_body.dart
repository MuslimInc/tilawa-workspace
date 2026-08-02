import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/layout/list_scroll_bottom_padding.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/khatma_plan.dart';
import '../../domain/entities/khatma_session.dart';
import '../screens/khatma_sessions_list_screen.dart';
import 'khatma_current_wird_card.dart';
import 'khatma_reminder_dialogs.dart';
import 'smart_khatma_plan_actions.dart';

class KhatmaActiveHubBody extends StatelessWidget {
  const KhatmaActiveHubBody({
    super.key,
    required this.plan,
    required this.todayTarget,
  });

  final KhatmaPlan plan;
  final KhatmaTodayTarget? todayTarget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final now = DateTime.now();
    final startPage = todayTarget?.startPage ?? plan.assignmentStartPage;
    final endPage = todayTarget?.endPage ?? plan.assignmentEndPage;
    final missedDays = todayTarget?.missedDays ?? plan.missedDays(now);
    final previousCount = KhatmaSessionSchedule.previousCount(plan);
    final upcomingCount = KhatmaSessionSchedule.upcomingCount(plan);
    final progressPercent = (plan.progress * 100).round();

    final double horizontalInset =
        theme.componentTokens.settingsGroup.groupHorizontalPadding;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalInset,
        tokens.spaceSection,
        horizontalInset,
        listScrollBottomPadding(context) + tokens.spaceLarge,
      ),
      children: [
        Text(
          context.l10n.khatmaCurrentWirdTitle,
          style: theme.textTheme.titleLarge,
        ),
        SizedBox(height: tokens.spaceMedium),
        KhatmaCurrentWirdCard(startPage: startPage, endPage: endPage),
        SizedBox(height: tokens.spaceLarge),
        Row(
          children: [
            Expanded(
              child: TilawaButton(
                text: context.l10n.khatmaReadWirdAction,
                onPressed: () => openKhatmaReaderAndRefresh(context, plan),
              ),
            ),
            SizedBox(width: tokens.spaceSmall),
            Expanded(
              child: TilawaButton(
                text: context.l10n.khatmaFinishedReadingAction,
                variant: TilawaButtonVariant.outline,
                onPressed: () => showKhatmaSaveProgressSheet(context, plan),
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spaceLarge),
        Text(
          context.l10n.khatmaProgressTitle,
          style: theme.textTheme.titleMedium,
        ),
        SizedBox(height: tokens.spaceSmall),
        Text(
          context.l10n.khatmaProgressSubtitle(
            plan.currentDay(now),
            plan.durationDays,
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.spaceMedium),
        ClipRRect(
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          child: LinearProgressIndicator(
            value: plan.progress,
            minHeight: tokens.spaceSmall,
          ),
        ),
        SizedBox(height: tokens.spaceSmall),
        Text(
          '$progressPercent%',
          style: theme.textTheme.labelLarge,
        ),
        SizedBox(height: tokens.spaceMedium),
        Row(
          children: [
            Expanded(
              child: TilawaButton(
                text: context.l10n.khatmaPreviousSessionsCount(previousCount),
                variant: TilawaButtonVariant.outline,
                onPressed: previousCount == 0
                    ? null
                    : () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => KhatmaSessionsListScreen(
                            title: context.l10n.khatmaPreviousSessionsTitle,
                            sessions: KhatmaSessionSchedule.previous(plan),
                          ),
                        ),
                      ),
              ),
            ),
            SizedBox(width: tokens.spaceSmall),
            Expanded(
              child: TilawaButton(
                text: context.l10n.khatmaUpcomingSessionsCount(upcomingCount),
                variant: TilawaButtonVariant.outline,
                onPressed: upcomingCount == 0
                    ? null
                    : () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => KhatmaSessionsListScreen(
                            title: context.l10n.khatmaUpcomingSessionsTitle,
                            sessions: KhatmaSessionSchedule.upcoming(plan),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spaceMedium),
        TilawaCard(
          surface: TilawaCardSurface.flat,
          child: Text(
            _statusMessage(context, plan, missedDays),
            style: theme.textTheme.bodyMedium,
          ),
        ),
        if (missedDays > 0) ...[
          SizedBox(height: tokens.spaceLarge),
          _KhatmaHubRecoveryPanel(
            onExtend: () {
              unawaited(confirmKhatmaExtension(context, plan));
            },
          ),
        ],
        SizedBox(height: tokens.spaceLarge),
        // Panel only — ListView already applies [groupHorizontalPadding].
        // [TilawaHubNavigationGroup] would double-inset the card.
        TilawaSettingsGroupPanel(
          style: TilawaSettingsGroupPanelStyle.hub,
          children: [
            TilawaNavigationRow(
              emphasis: TilawaNavigationRowEmphasis.secondary,
              icon: Icons.notifications_outlined,
              title: context.l10n.khatmaReminderSettingsTitle,
              subtitle: context.l10n.khatmaReminderSettingsSubtitle,
              semanticTint: TilawaSemanticTint.scholar,
              onTap: () => showKhatmaReminderSettingsSheet(context),
            ),
            TilawaNavigationRow(
              emphasis: TilawaNavigationRowEmphasis.secondary,
              icon: Icons.edit_outlined,
              title: context.l10n.khatmaEditPlanAction,
              subtitle: context.l10n.khatmaEditPlanSubtitle,
              semanticTint: TilawaSemanticTint.scholar,
              onTap: () => showKhatmaEditPlanSheet(context, plan),
            ),
            TilawaNavigationRow(
              emphasis: TilawaNavigationRowEmphasis.tertiary,
              icon: Icons.delete_outline_rounded,
              title: context.l10n.khatmaDeletePlanAction,
              subtitle: context.l10n.khatmaHubResetSubtitle,
              semanticTint: TilawaSemanticTint.neutral,
              showsNavigationChevron: false,
              onTap: () => confirmKhatmaPlanReset(context),
              showDivider: false,
            ),
          ],
        ),
      ],
    );
  }

  String _statusMessage(
    BuildContext context,
    KhatmaPlan plan,
    int missedDays,
  ) {
    if (plan.isTodayCompleted) {
      return context.l10n.khatmaTodayCompletedTitle;
    }
    if (missedDays > 0) {
      return context.l10n.khatmaBehindSchedule(missedDays);
    }
    return context.l10n.khatmaOnTrack;
  }
}

class _KhatmaHubRecoveryPanel extends StatelessWidget {
  const _KhatmaHubRecoveryPanel({
    required this.onExtend,
  });

  final VoidCallback onExtend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return TilawaCard(
      surface: TilawaCardSurface.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spaceSmall,
        children: [
          Text(
            context.l10n.khatmaAdjustedPlan,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          TilawaButton(
            text: context.l10n.khatmaExtendAction,
            variant: TilawaButtonVariant.outline,
            onPressed: onExtend,
          ),
        ],
      ),
    );
  }
}
