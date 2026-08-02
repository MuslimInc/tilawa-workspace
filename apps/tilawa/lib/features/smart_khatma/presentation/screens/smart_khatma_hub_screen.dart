import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/app_review/data/config/app_review_store_config.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../data/khatma_reminder_notification_service.dart';
import '../../domain/entities/khatma_plan.dart';
import '../bloc/khatma_plan_bloc.dart';
import '../bloc/khatma_plan_event.dart';
import '../bloc/khatma_plan_state.dart';
import '../formatters/khatma_page_range_text.dart';
import '../widgets/khatma_active_hub_body.dart';
import '../widgets/khatma_reminder_dialogs.dart';
import '../widgets/setup/khatma_setup_wizard.dart';
import '../widgets/smart_khatma_plan_actions.dart';
import 'khatma_completion_dua_screen.dart';

/// Feature hub for Smart Khatma — setup wizard, current wird, completion.
class SmartKhatmaHubScreen extends StatelessWidget {
  const SmartKhatmaHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TilawaShellChildScaffold(
      appBar: TilawaCatalogAppBar.titleOnly(
        title: context.l10n.khatmaHubTitle,
        automaticallyImplyLeading: true,
        onBackPressed: () => context.pop(),
      ),
      body: BlocConsumer<KhatmaPlanBloc, KhatmaPlanState>(
        listenWhen: (previous, current) {
          final bool wasWithoutPlan =
              previous is KhatmaPlanLoaded && previous.plan == null ||
              previous is KhatmaPlanCreationReview;
          final bool nowHasActivePlan =
              current is KhatmaPlanLoaded &&
              current.plan != null &&
              !current.plan!.isCompleted;
          return wasWithoutPlan && nowHasActivePlan;
        },
        listener: (context, state) {
          unawaited(_afterPlanCreated(context));
        },
        builder: (context, state) {
          return switch (state) {
            KhatmaPlanLoaded(:final plan, :final todayTarget) =>
              plan == null
                  ? const KhatmaSetupWizard()
                  : plan.isCompleted
                  ? const _KhatmaHubCompletedBody()
                  : KhatmaActiveHubBody(plan: plan, todayTarget: todayTarget),
            KhatmaPlanCreationReview(:final plan, :final isEditing) =>
              _KhatmaCreationReviewBody(
                plan: plan,
                isEditing: isEditing,
              ),
            KhatmaPlanFailure() => const _KhatmaHubErrorBody(),
            _ => const Center(child: TilawaLoadingIndicator()),
          };
        },
      ),
    );
  }
}

Future<void> _afterPlanCreated(BuildContext context) async {
  await promptKhatmaDailyReminder(context);
  if (!context.mounted) return;
  await promptKhatmaSurahReminders(context);
}

class _KhatmaHubCompletedBody extends StatelessWidget {
  const _KhatmaHubCompletedBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(
        theme.componentTokens.settingsGroup.groupHorizontalPadding,
        tokens.spaceLarge,
        theme.componentTokens.settingsGroup.groupHorizontalPadding,
        tokens.spaceLarge,
      ),
      children: [
        TilawaButton(
          text: context.l10n.khatmaCompletionDuaAction,
          onPressed: () {
            unawaited(
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const KhatmaCompletionDuaScreen(),
                ),
              ),
            );
          },
        ),
        SizedBox(height: tokens.spaceLarge),
        Text(
          context.l10n.khatmaCompletionDoneMessage,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: tokens.spaceSmall),
        Text(
          context.l10n.khatmaCompletedSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: tokens.spaceLarge),
        TilawaButton(
          text: context.l10n.khatmaCompletionShareAction,
          variant: TilawaButtonVariant.outline,
          onPressed: () => unawaited(_shareCompletion(context)),
        ),
        SizedBox(height: tokens.spaceSmall),
        TilawaButton(
          text: context.l10n.khatmaStartAnotherAction,
          onPressed: () async {
            if (getIt.isRegistered<KhatmaReminderNotificationService>()) {
              await getIt<KhatmaReminderNotificationService>()
                  .clearOnPlanReset();
            }
            if (!context.mounted) return;
            context.read<KhatmaPlanBloc>().add(
              const KhatmaPlanResetRequested(),
            );
          },
        ),
        SizedBox(height: tokens.spaceSmall),
        TilawaButton(
          text: context.l10n.khatmaReturnToQuranAction,
          variant: TilawaButtonVariant.outline,
          onPressed: () => const QuranIndexRoute().go(context),
        ),
      ],
    );
  }

  Future<void> _shareCompletion(BuildContext context) async {
    final String text = context.l10n.khatmaCompletionShareText(
      AppReviewStoreConfig.appStoreListingUriFor(null).toString(),
      AppReviewStoreConfig.playStoreListingUriFor(null).toString(),
    );
    await SharePlus.instance.share(ShareParams(text: text));
  }
}

class _KhatmaCreationReviewBody extends StatelessWidget {
  const _KhatmaCreationReviewBody({
    required this.plan,
    this.isEditing = false,
  });

  final KhatmaPlan plan;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(
        theme.componentTokens.settingsGroup.groupHorizontalPadding,
        tokens.spaceLarge,
        theme.componentTokens.settingsGroup.groupHorizontalPadding,
        tokens.spaceLarge,
      ),
      children: [
        Text(
          isEditing
              ? context.l10n.khatmaEditPlanTitle
              : context.l10n.khatmaReviewPlanTitle,
          style: theme.textTheme.headlineSmall,
        ),
        SizedBox(height: tokens.spaceLarge),
        TilawaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: tokens.spaceMedium,
            children: [
              Text(
                formatKhatmaPageRange(
                  context.l10n,
                  isEditing ? plan.startPage : plan.assignmentStartPage,
                  isEditing ? plan.targetPage : plan.assignmentEndPage,
                ),
              ),
              if (!isEditing)
                Text(context.l10n.khatmaDailyPages(plan.assignedTodayPages))
              else
                Text(context.l10n.khatmaDailyPages(plan.plannedDailyPages())),
              Text(context.l10n.khatmaTotalPages(plan.totalPages)),
              if (!isEditing) ...[
                Text(context.l10n.khatmaStartPage(plan.startPage)),
                Text(context.l10n.khatmaTargetPage(plan.targetPage)),
              ] else
                Text(context.l10n.khatmaDurationDays(plan.durationDays)),
              Text(
                context.l10n.khatmaExpectedCompletionDate(
                  MaterialLocalizations.of(context).formatMediumDate(
                    plan.expectedCompletionDate,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spaceLarge),
        TilawaButton(
          text: isEditing
              ? context.l10n.khatmaSavePlanChangesAction
              : context.l10n.khatmaConfirmPlanAction,
          onPressed: () {
            if (isEditing) {
              context.read<KhatmaPlanBloc>().add(
                KhatmaPlanEditConfirmed(
                  plan: plan,
                  durationDays: plan.durationDays,
                ),
              );
            } else {
              context.read<KhatmaPlanBloc>().add(
                KhatmaPlanCreationConfirmed(plan),
              );
            }
          },
        ),
        SizedBox(height: tokens.spaceSmall),
        TilawaButton(
          text: context.l10n.cancel,
          variant: TilawaButtonVariant.outline,
          onPressed: () => context.read<KhatmaPlanBloc>().add(
            const KhatmaPlanStarted(),
          ),
        ),
      ],
    );
  }
}

class _KhatmaHubErrorBody extends StatelessWidget {
  const _KhatmaHubErrorBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        theme.componentTokens.settingsGroup.groupHorizontalPadding,
        context.tokens.spaceLarge,
        theme.componentTokens.settingsGroup.groupHorizontalPadding,
        context.tokens.spaceLarge,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: context.tokens.spaceMedium,
        children: [
          Text(
            context.l10n.khatmaUnavailable,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          TilawaButton(
            text: context.l10n.retry,
            variant: TilawaButtonVariant.outline,
            onPressed: () => context.read<KhatmaPlanBloc>().add(
              const KhatmaPlanStarted(),
            ),
          ),
          TilawaButton(
            text: context.l10n.khatmaDeletePlanAction,
            variant: TilawaButtonVariant.outline,
            onPressed: () => confirmKhatmaPlanReset(context),
          ),
        ],
      ),
    );
  }
}
