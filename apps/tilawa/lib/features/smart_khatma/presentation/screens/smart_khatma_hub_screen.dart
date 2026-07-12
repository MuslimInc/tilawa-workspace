import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/shared/widgets/quran_player_widget.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/khatma_plan.dart';
import '../bloc/khatma_plan_bloc.dart';
import '../bloc/khatma_plan_event.dart';
import '../bloc/khatma_plan_state.dart';
import '../widgets/smart_khatma_plan_actions.dart';

/// Feature hub for Smart Khatma — hero summary, plan actions, and navigation.
class SmartKhatmaHubScreen extends StatelessWidget {
  const SmartKhatmaHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final double fabBottomOffset =
        QuranPlayerWidget.fabBottomOffset(context) + tokens.spaceLarge;

    return Scaffold(
      appBar: TilawaCatalogAppBar.titleOnly(
        title: context.l10n.khatmaHubTitle,
        automaticallyImplyLeading: true,
        onBackPressed: () => context.pop(),
      ),
      body: BlocBuilder<KhatmaPlanBloc, KhatmaPlanState>(
        builder: (context, state) {
          return switch (state) {
            KhatmaPlanLoaded(:final plan, :final todayTarget) =>
              plan == null
                  ? const _KhatmaHubEmptyBody()
                  : _KhatmaHubActiveBody(plan: plan, todayTarget: todayTarget),
            KhatmaPlanFailure(:final message) => _KhatmaHubErrorBody(
              message: message,
            ),
            _ => const Center(child: TilawaLoadingIndicator()),
          };
        },
      ),
      floatingActionButton: BlocBuilder<KhatmaPlanBloc, KhatmaPlanState>(
        buildWhen: (previous, current) =>
            current is KhatmaPlanLoaded && current.plan != null,
        builder: (context, state) {
          if (state is! KhatmaPlanLoaded || state.plan == null) {
            return const SizedBox.shrink();
          }
          return TilawaPrimaryFab(
            heroTag: 'smart_khatma_continue_fab',
            icon: Icons.menu_book_rounded,
            semanticLabel: context.l10n.khatmaContinueReading,
            onPressed: () => openKhatmaReaderAndRefresh(context),
          );
        },
      ),
      floatingActionButtonLocation: TilawaFabLocation.placement(
        TilawaFabPlacement.start,
        bottomOffset: fabBottomOffset,
      ),
    );
  }
}

class _KhatmaHubEmptyBody extends StatelessWidget {
  const _KhatmaHubEmptyBody();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bool isLoading = context.select<KhatmaPlanBloc, bool>(
      (bloc) => bloc.state is KhatmaPlanLoading,
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceMedium,
        tokens.spaceSection,
        tokens.spaceMedium,
        tokens.spaceHuge,
      ),
      children: [
        TilawaHeroSummaryCard(
          label: context.l10n.khatmaEmptyTitle,
          metric: '—',
          badges: const [],
        ),
        SizedBox(height: tokens.spaceLarge),
        Text(
          context.l10n.khatmaEmptySubtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.spaceLarge),
        Wrap(
          spacing: tokens.spaceSmall,
          runSpacing: tokens.spaceSmall,
          children: [
            for (final days in const [7, 15, 30, 60])
              TilawaButton(
                text: context.l10n.khatmaDurationDays(days),
                variant: TilawaButtonVariant.outline,
                onPressed: isLoading
                    ? null
                    : () {
                        context.read<KhatmaPlanBloc>().add(
                          KhatmaPlanQuickStartRequested(days),
                        );
                      },
              ),
          ],
        ),
      ],
    );
  }
}

class _KhatmaHubActiveBody extends StatelessWidget {
  const _KhatmaHubActiveBody({
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
    final progressPercent = (plan.progress * 100).round();
    final targetPages = todayTarget?.pages ?? plan.todayTargetPages(now);
    final startPage = todayTarget?.startPage ?? plan.currentPage;
    final missedDays = todayTarget?.missedDays ?? 0;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        0,
        tokens.spaceSection,
        0,
        tokens.spaceHuge + kMeMuslimMinInteractiveDimension,
      ),
      children: [
        TilawaHeroSummaryCard(
          label: context.l10n.khatmaProgressSubtitle(
            plan.currentDay(now),
            plan.durationDays,
          ),
          metric: '$progressPercent%',
          badges: [
            TilawaHeroSummaryBadge(
              label: context.l10n.khatmaPagesShort(targetPages),
              icon: Icons.today_outlined,
              tint: TilawaSemanticTint.ink,
            ),
            TilawaHeroSummaryBadge(
              label: context.l10n.khatmaPagesShort(plan.remainingPages),
              tint: TilawaSemanticTint.parchment,
            ),
            TilawaHeroSummaryBadge(
              label: context.l10n.khatmaDaysShort(plan.remainingDays(now)),
              tint: TilawaSemanticTint.scholar,
            ),
          ],
          footer: _KhatmaHubProgressBar(
            value: plan.progress,
            percent: progressPercent,
          ),
        ),
        if (missedDays > 0) ...[
          SizedBox(height: tokens.spaceLarge),
          Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal:
                  theme.componentTokens.settingsGroup.groupHorizontalPadding,
            ),
            child: _KhatmaHubRecoveryPanel(
              onCatchUp: () {
                context.read<KhatmaPlanBloc>().add(
                  const KhatmaPlanCatchUpSelected(),
                );
                openKhatmaReaderAndRefresh(context);
              },
              onExtend: () {
                context.read<KhatmaPlanBloc>().add(
                  const KhatmaPlanExtendSelected(),
                );
              },
            ),
          ),
        ],
        SizedBox(height: tokens.spaceLarge),
        TilawaHubNavigationGroup(
          children: [
            TilawaNavigationRow(
              icon: Icons.menu_book_rounded,
              title: context.l10n.khatmaContinueReading,
              subtitle: context.l10n.khatmaContinueFromPage(startPage),
              semanticTint: TilawaSemanticTint.ink,
              onTap: () => openKhatmaReaderAndRefresh(context),
            ),
            TilawaNavigationRow(
              icon: FluentIcons.target_24_regular,
              title: context.l10n.khatmaTodayGoal,
              subtitle: context.l10n.khatmaPagesShort(targetPages),
              semanticTint: TilawaSemanticTint.scholar,
              onTap: () => openKhatmaReaderAndRefresh(context),
            ),
            TilawaNavigationRow(
              icon: Icons.restart_alt_rounded,
              title: context.l10n.khatmaResetAction,
              subtitle: context.l10n.khatmaHubResetSubtitle,
              semanticTint: TilawaSemanticTint.neutral,
              onTap: () => confirmKhatmaPlanReset(context),
              showDivider: false,
            ),
          ],
        ),
      ],
    );
  }
}

class _KhatmaHubProgressBar extends StatelessWidget {
  const _KhatmaHubProgressBar({
    required this.value,
    required this.percent,
  });

  final double value;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              tokens.resolveRadius(
                family: TilawaRadiusFamily.decorative,
                height: 6,
              ),
            ),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        SizedBox(width: tokens.spaceSmall),
        Text(
          '$percent%',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _KhatmaHubRecoveryPanel extends StatelessWidget {
  const _KhatmaHubRecoveryPanel({
    required this.onCatchUp,
    required this.onExtend,
  });

  final VoidCallback onCatchUp;
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
          Wrap(
            spacing: tokens.spaceSmall,
            runSpacing: tokens.spaceSmall,
            children: [
              TilawaButton(
                text: context.l10n.khatmaCatchUpAction,
                variant: TilawaButtonVariant.secondary,
                onPressed: onCatchUp,
              ),
              TilawaButton(
                text: context.l10n.khatmaExtendAction,
                variant: TilawaButtonVariant.outline,
                onPressed: onExtend,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KhatmaHubErrorBody extends StatelessWidget {
  const _KhatmaHubErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.tokens.spaceLarge),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
