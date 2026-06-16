import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/khatma_plan.dart';
import '../bloc/khatma_plan_bloc.dart';
import '../bloc/khatma_plan_event.dart';
import '../bloc/khatma_plan_state.dart';

class SmartKhatmaCard extends StatelessWidget {
  const SmartKhatmaCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KhatmaPlanBloc, KhatmaPlanState>(
      builder: (context, state) {
        return switch (state) {
          KhatmaPlanLoaded(:final plan, :final todayTarget) =>
            plan == null
                ? const _KhatmaEmptyCard()
                : _KhatmaDashboardCard(plan: plan, todayTarget: todayTarget),
          KhatmaPlanFailure(:final message) => _KhatmaFailureCard(
            message: message,
          ),
          _ => const _KhatmaLoadingCard(),
        };
      },
    );
  }
}

class _KhatmaEmptyCard extends StatelessWidget {
  const _KhatmaEmptyCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    return TilawaCard(
      surface: TilawaCardSurface.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spaceMedium,
        children: [
          _KhatmaHeader(
            title: context.l10n.khatmaEmptyTitle,
            subtitle: context.l10n.khatmaEmptySubtitle,
          ),
          Wrap(
            spacing: tokens.spaceSmall,
            runSpacing: tokens.spaceSmall,
            children: [
              for (final days in const [7, 15, 30, 60])
                OutlinedButton(
                  onPressed: () {
                    context.read<KhatmaPlanBloc>().add(
                      KhatmaPlanQuickStartRequested(days),
                    );
                  },
                  child: Text(context.l10n.khatmaDurationDays(days)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KhatmaDashboardCard extends StatelessWidget {
  const _KhatmaDashboardCard({required this.plan, required this.todayTarget});

  final KhatmaPlan plan;
  final KhatmaTodayTarget? todayTarget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final progressPercent = (plan.progress * 100).round();
    final targetPages =
        todayTarget?.pages ?? plan.todayTargetPages(DateTime.now());
    final startPage = todayTarget?.startPage ?? plan.currentPage;
    final missedDays = todayTarget?.missedDays ?? 0;

    return TilawaCard(
      surface: TilawaCardSurface.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spaceMedium,
        children: [
          _KhatmaHeader(
            title: context.l10n.khatmaProgressTitle,
            subtitle: context.l10n.khatmaProgressSubtitle(
              plan.currentDay(DateTime.now()),
              plan.durationDays,
            ),
          ),
          Text(
            context.l10n.khatmaContinueFromPage(startPage),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          _KhatmaProgressBar(value: plan.progress, percent: progressPercent),
          Row(
            children: [
              _KhatmaMetric(
                label: context.l10n.khatmaTodayGoal,
                value: context.l10n.khatmaPagesShort(targetPages),
              ),
              _KhatmaMetric(
                label: context.l10n.khatmaRemainingPages,
                value: context.l10n.khatmaPagesShort(plan.remainingPages),
              ),
              _KhatmaMetric(
                label: context.l10n.khatmaRemaining,
                value: context.l10n.khatmaDaysShort(
                  plan.remainingDays(DateTime.now()),
                ),
              ),
            ],
          ),
          if (missedDays > 0)
            _KhatmaRecoveryActions(
              onCatchUp: () {
                context.read<KhatmaPlanBloc>().add(
                  const KhatmaPlanCatchUpSelected(),
                );
                _openReaderAndRefresh(context);
              },
              onExtend: () {
                context.read<KhatmaPlanBloc>().add(
                  const KhatmaPlanExtendSelected(),
                );
              },
            ),
          Row(
            children: [
              TextButton(
                onPressed: () => _confirmReset(context),
                child: Text(context.l10n.khatmaResetAction),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _openReaderAndRefresh(context),
                icon: const Icon(Icons.menu_book_rounded),
                label: Text(context.l10n.khatmaContinueReading),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.l10n.khatmaResetTitle),
          content: Text(context.l10n.khatmaResetMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n.reset),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    context.read<KhatmaPlanBloc>().add(const KhatmaPlanResetRequested());
  }

  Future<void> _openReaderAndRefresh(BuildContext context) async {
    await const QuranLastReadRoute().push(context);
    if (!context.mounted) {
      return;
    }
    context.read<KhatmaPlanBloc>().add(const KhatmaPlanStarted());
  }
}

class _KhatmaProgressBar extends StatelessWidget {
  const _KhatmaProgressBar({required this.value, required this.percent});

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

class _KhatmaRecoveryActions extends StatelessWidget {
  const _KhatmaRecoveryActions({
    required this.onCatchUp,
    required this.onExtend,
  });

  final VoidCallback onCatchUp;
  final VoidCallback onExtend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    return Column(
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
            FilledButton.tonal(
              onPressed: onCatchUp,
              child: Text(context.l10n.khatmaCatchUpAction),
            ),
            OutlinedButton(
              onPressed: onExtend,
              child: Text(context.l10n.khatmaExtendAction),
            ),
          ],
        ),
      ],
    );
  }
}

class _KhatmaMetric extends StatelessWidget {
  const _KhatmaMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _KhatmaHeader extends StatelessWidget {
  const _KhatmaHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _KhatmaLoadingCard extends StatelessWidget {
  const _KhatmaLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const TilawaCard(
      surface: TilawaCardSurface.raised,
      child: TilawaLoadingIndicator(centered: false),
    );
  }
}

class _KhatmaFailureCard extends StatelessWidget {
  const _KhatmaFailureCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return TilawaCard(
      surface: TilawaCardSurface.raised,
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
