import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../bloc/khatma_plan_bloc.dart';
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
          KhatmaPlanLoaded(:final plan, :final todayTarget) =>
            plan == null
                ? _KhatmaHomeEmptyEntry(onOpenHub: () => _openHub(context))
                : _KhatmaHomeActiveEntry(
                    planProgress: (plan.progress * 100).round(),
                    subtitle: context.l10n.khatmaProgressSubtitle(
                      plan.currentDay(DateTime.now()),
                      plan.durationDays,
                    ),
                    todayPages:
                        todayTarget?.pages ??
                        plan.todayTargetPages(DateTime.now()),
                    onOpenHub: () => _openHub(context),
                  ),
          KhatmaPlanFailure(:final message) => TilawaCard(
            surface: TilawaCardSurface.raised,
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          _ => const TilawaCard(
            surface: TilawaCardSurface.raised,
            child: TilawaLoadingIndicator(centered: false),
          ),
        };
      },
    );
  }

  Future<void> _openHub(BuildContext context) async {
    await const SmartKhatmaHubRoute().push(context);
    if (!context.mounted) {
      return;
    }
    context.read<KhatmaPlanBloc>().add(const KhatmaPlanStarted());
  }
}

class _KhatmaHomeEmptyEntry extends StatelessWidget {
  const _KhatmaHomeEmptyEntry({required this.onOpenHub});

  final VoidCallback onOpenHub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return TilawaCard(
      surface: TilawaCardSurface.raised,
      onTap: onOpenHub,
      child: Row(
        children: [
          TilawaIconBox(
            icon: Icons.auto_stories_outlined,
            variant: TilawaIconBoxVariant.tinted,
            semanticTint: TilawaSemanticTint.ink,
          ),
          SizedBox(width: tokens.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spaceExtraSmall,
              children: [
                Text(
                  context.l10n.khatmaEmptyTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  context.l10n.khatmaEmptySubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _KhatmaHomeActiveEntry extends StatelessWidget {
  const _KhatmaHomeActiveEntry({
    required this.planProgress,
    required this.subtitle,
    required this.todayPages,
    required this.onOpenHub,
  });

  final int planProgress;
  final String subtitle;
  final int todayPages;
  final VoidCallback onOpenHub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return TilawaCard(
      surface: TilawaCardSurface.raised,
      onTap: onOpenHub,
      child: Row(
        children: [
          TilawaIconBox(
            icon: Icons.auto_stories_outlined,
            variant: TilawaIconBoxVariant.tinted,
            semanticTint: TilawaSemanticTint.scholar,
          ),
          SizedBox(width: tokens.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spaceExtraSmall,
              children: [
                Text(
                  context.l10n.khatmaProgressTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${context.l10n.khatmaTodayGoal}: '
                  '${context.l10n.khatmaPagesShort(todayPages)} · '
                  '$planProgress%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: tokens.spaceExtraSmall,
            children: [
              Text(
                context.l10n.khatmaHomeViewPlan,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
