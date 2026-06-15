import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/today_plan.dart';
import '../bloc/today_plan_bloc.dart';
import '../bloc/today_plan_event.dart';
import '../bloc/today_plan_state.dart';

class TodayPlanCard extends StatelessWidget {
  const TodayPlanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodayPlanBloc, TodayPlanState>(
      builder: (context, state) {
        return switch (state) {
          TodayPlanLoaded(:final plan) => _TodayPlanLoadedCard(plan: plan),
          TodayPlanFailure(:final message) => _TodayPlanFailureCard(
            message: message,
          ),
          _ => const _TodayPlanLoadingCard(),
        };
      },
    );
  }
}

class _TodayPlanLoadedCard extends StatelessWidget {
  const _TodayPlanLoadedCard({required this.plan});

  final TodayPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Semantics(
      container: true,
      label: context.l10n.todayPlanTitle,
      value: context.l10n.todayPlanProgress(
        plan.completedCount,
        plan.totalCount,
        plan.minutesRemaining,
      ),
      child: TilawaCard(
        surface: TilawaCardSurface.raised,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spaceMedium,
          children: [
            _TodayPlanHeader(plan: plan),
            ClipRRect(
              borderRadius: BorderRadius.circular(
                tokens.resolveRadius(
                  family: TilawaRadiusFamily.decorative,
                  height: 4,
                ),
              ),
              child: LinearProgressIndicator(
                value: plan.progress,
                minHeight: 4,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
            Column(
              spacing: tokens.spaceSmall,
              children: [
                for (final TodayPlanTask task in plan.tasks)
                  _TodayPlanTaskRow(task: task),
              ],
            ),
            _TodayPlanFooter(plan: plan),
          ],
        ),
      ),
    );
  }
}

class _TodayPlanHeader extends StatelessWidget {
  const _TodayPlanHeader({required this.plan});

  final TodayPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.todayPlanTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                plan.isCompleted
                    ? context.l10n.todayPlanMotivationComplete
                    : context.l10n.todayPlanMotivationDefault,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        _TodayPlanStreakChip(streakDays: plan.streakDays),
      ],
    );
  }
}

class _TodayPlanStreakChip extends StatelessWidget {
  const _TodayPlanStreakChip({required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final int displayDays = streakDays == 0 ? 1 : streakDays;

    return Container(
      constraints: const BoxConstraints(
        minHeight: kTilawaMinInteractiveDimension,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSmall,
        vertical: tokens.spaceExtraSmall,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(
          tokens.resolveRadius(
            family: TilawaRadiusFamily.pill,
            height: kTilawaMinInteractiveDimension,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, size: tokens.iconSizeSmall),
          SizedBox(width: tokens.spaceExtraSmall),
          Text(
            context.l10n.todayPlanStreakDays(displayDays),
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayPlanTaskRow extends StatelessWidget {
  const _TodayPlanTaskRow({required this.task});

  final TodayPlanTask task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final bool completed = task.isCompleted;

    return InkWell(
      onTap: () {
        context.read<TodayPlanBloc>().add(TodayPlanTaskToggled(task));
      },
      borderRadius: BorderRadius.circular(
        tokens.resolveRadius(
          family: TilawaRadiusFamily.chrome,
          height: kTilawaMinInteractiveDimension,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.spaceExtraSmall),
        child: Row(
          children: [
            Icon(
              completed
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: completed
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: tokens.iconSizeMedium,
            ),
            SizedBox(width: tokens.spaceSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleFor(context, task),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: completed
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface,
                      decoration: completed
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  if (_subtitleFor(context, task) != null)
                    Text(
                      _subtitleFor(context, task)!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              context.l10n.todayPlanMinutesShort(task.minutes),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleFor(BuildContext context, TodayPlanTask task) {
    return switch (task.kind) {
      TodayPlanTaskKind.reading => context.l10n.todayPlanReadPages(
        task.metadata['pages'] as int? ?? 2,
      ),
      TodayPlanTaskKind.listening =>
        task.metadata['surah_name'] == null
            ? context.l10n.todayPlanListenMinutes(task.minutes)
            : context.l10n.todayPlanContinueListening,
      TodayPlanTaskKind.adhkar => context.l10n.todayPlanMorningAdhkar,
      TodayPlanTaskKind.tasbeeh => context.l10n.todayPlanTasbeehGoal,
    };
  }

  String? _subtitleFor(BuildContext context, TodayPlanTask task) {
    return switch (task.kind) {
      TodayPlanTaskKind.reading => switch (task.metadata['page']) {
        final int page => context.l10n.todayPlanContinueFromPage(page),
        _ => context.l10n.todayPlanShortReadingSession,
      },
      TodayPlanTaskKind.listening => switch ((
        task.metadata['surah_name'],
        task.metadata['reciter_name'],
      )) {
        (final String surahName, final String reciterName) =>
          context.l10n.todayPlanListeningSubtitle(surahName, reciterName),
        _ => context.l10n.todayPlanChooseReciter,
      },
      TodayPlanTaskKind.adhkar => context.l10n.todayPlanMorningAdhkarSubtitle,
      TodayPlanTaskKind.tasbeeh => null,
    };
  }
}

class _TodayPlanFooter extends StatelessWidget {
  const _TodayPlanFooter({required this.plan});

  final TodayPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.todayPlanProgress(
              plan.completedCount,
              plan.totalCount,
              plan.minutesRemaining,
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(width: tokens.spaceSmall),
        FilledButton.icon(
          onPressed: plan.isCompleted
              ? null
              : () {
                  context.read<TodayPlanBloc>().add(
                    const TodayPlanContinuePressed(),
                  );
                  _openReaderAndRefreshPlans(context);
                },
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(context.l10n.todayPlanContinue),
        ),
      ],
    );
  }

  Future<void> _openReaderAndRefreshPlans(BuildContext context) async {
    await const QuranLastReadRoute().push(context);
    if (!context.mounted) {
      return;
    }
    context.read<KhatmaPlanBloc>().add(const KhatmaPlanStarted());
    context.read<TodayPlanBloc>().add(const TodayPlanSourceChanged());
  }
}

class _TodayPlanLoadingCard extends StatelessWidget {
  const _TodayPlanLoadingCard();

  @override
  Widget build(BuildContext context) {
    return TilawaCard(
      surface: TilawaCardSurface.raised,
      child: const Center(
        child: TilawaLoadingIndicator(centered: false),
      ),
    );
  }
}

class _TodayPlanFailureCard extends StatelessWidget {
  const _TodayPlanFailureCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TilawaCard(
      surface: TilawaCardSurface.raised,
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
