import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_card.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../bloc/khatma_plan_bloc.dart';
import 'khatma_home_destination_card.dart';
import '../bloc/khatma_plan_event.dart';
import '../bloc/khatma_plan_state.dart';

/// Compact home-dashboard entry that opens the Smart Khatma hub.
class SmartKhatmaHomeEntryCard extends StatelessWidget {
  const SmartKhatmaHomeEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KhatmaPlanBloc, KhatmaPlanState>(
      builder: (context, state) {
        return switch (state) {
          KhatmaPlanLoaded(:final plan) =>
            plan == null
                ? _KhatmaHomeEmptyEntry(onOpenHub: () => _openHub(context))
                : plan.isCompleted
                ? _KhatmaHomeCompletedEntry(onOpenHub: () => _openHub(context))
                : _KhatmaHomeActiveEntry(
                    planProgress: (plan.progress * 100).round(),
                    subtitle: context.l10n.khatmaProgressSubtitle(
                      plan.currentDay(DateTime.now()),
                      plan.durationDays,
                    ),
                    todayCompletedPages: plan.confirmedTodayPages,
                    todayRemainingPages: plan.remainingTodayPages,
                    rangeStart: plan.assignmentStartPage,
                    rangeEnd: plan.assignmentEndPage,
                    isTodayCompleted: plan.isTodayCompleted,
                    onOpenHub: () => _openHub(context),
                  ),
          KhatmaPlanFailure() => KhatmaHomeDestinationCard(
            icon: Icons.refresh_rounded,
            onTap: () => context.read<KhatmaPlanBloc>().add(
              const KhatmaPlanStarted(),
            ),
            title: context.l10n.khatmaProgressTitle,
            subtitle: context.l10n.khatmaUnavailable,
          ),
          _ => const HomeDashboardCard(
            surface: TilawaCardSurface.raised,
            child: TilawaLoadingIndicator(centered: false),
          ),
        };
      },
    );
  }

  Future<void> _openHub(BuildContext context) async {
    await const SmartKhatmaHubRoute().push<void>(context);
    if (!context.mounted) {
      return;
    }
    context.read<KhatmaPlanBloc>().add(const KhatmaPlanStarted());
  }
}

class _KhatmaHomeCompletedEntry extends StatelessWidget {
  const _KhatmaHomeCompletedEntry({required this.onOpenHub});

  final VoidCallback onOpenHub;

  @override
  Widget build(BuildContext context) => KhatmaHomeDestinationCard(
    icon: Icons.auto_awesome_rounded,
    onTap: onOpenHub,
    title: context.l10n.khatmaCompletedTitle,
    subtitle: context.l10n.khatmaCompletedSubtitle,
  );
}

class _KhatmaHomeEmptyEntry extends StatelessWidget {
  const _KhatmaHomeEmptyEntry({required this.onOpenHub});

  final VoidCallback onOpenHub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return KhatmaHomeDestinationCard(
      icon: Icons.auto_stories_outlined,
      onTap: onOpenHub,
      title: context.l10n.khatmaEmptyTitle,
      subtitle: context.l10n.khatmaEmptySubtitle,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.86),
        size: tokens.iconSizeSmall,
      ),
    );
  }
}

class _KhatmaHomeActiveEntry extends StatelessWidget {
  const _KhatmaHomeActiveEntry({
    required this.planProgress,
    required this.subtitle,
    required this.todayCompletedPages,
    required this.todayRemainingPages,
    required this.rangeStart,
    required this.rangeEnd,
    required this.isTodayCompleted,
    required this.onOpenHub,
  });

  final int planProgress;
  final String subtitle;
  final int todayCompletedPages;
  final int todayRemainingPages;
  final int rangeStart;
  final int rangeEnd;
  final bool isTodayCompleted;
  final VoidCallback onOpenHub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final String detail = isTodayCompleted
        ? context.l10n.khatmaTodayCompletedTitle
        : '${context.l10n.khatmaRangePages(rangeStart, rangeEnd)} · '
              '${context.l10n.khatmaConfirmedAndRemaining(
                todayCompletedPages,
                todayRemainingPages,
              )} · $planProgress%';

    return KhatmaHomeDestinationCard(
      icon: Icons.auto_stories_outlined,
      onTap: onOpenHub,
      title: context.l10n.khatmaProgressTitle,
      subtitle: '$subtitle\n$detail',
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: tokens.spaceExtraSmall,
        children: [
          Text(
            context.l10n.khatmaHomeViewPlan,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onPrimary.withValues(alpha: 0.86),
            size: tokens.iconSizeSmall,
          ),
        ],
      ),
    );
  }
}
