import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/athkar/presentation/athkar_category_presentation.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_state.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_dashboard_card.dart';
import 'home_dashboard_section.dart';
import 'home_primary_action_card.dart';

/// Primary daily athkar habit — time-prioritized with completion status.
///
/// Surfaces the urgent morning/evening row from [HomeAthkarCompactCubit]
/// directly under [HomeQuickActionsSection].
class HomeMorningAthkarSection extends StatelessWidget {
  const HomeMorningAthkarSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeAthkarCompactCubit, HomeAthkarCompactState>(
      builder: (context, state) {
        if (state.status == HomeAthkarRowStatus.initial ||
            state.status == HomeAthkarRowStatus.loading) {
          return HomeDashboardSection(
            title: context.l10n.homeDailyHabitTitle,
            subtitle: context.l10n.homeDailyHabitSubtitle,
            child: const HomeDashboardCard(
              surface: TilawaCardSurface.raised,
              child: TilawaLoadingIndicator(),
            ),
          );
        }

        final HomeAthkarRowState? row = urgentHomeAthkarRow(state);
        if (row == null) {
          return const SizedBox.shrink();
        }

        return HomeDashboardSection(
          title: context.l10n.homeDailyHabitTitle,
          subtitle: context.l10n.homeDailyHabitSubtitle,
          child: HomeDailyAthkarHabitCard(row: row),
        );
      },
    );
  }
}

/// Strong daily habit card with Not started / In progress / Completed status.
class HomeDailyAthkarHabitCard extends StatelessWidget {
  const HomeDailyAthkarHabitCard({super.key, required this.row});

  final HomeAthkarRowState row;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String title = localizedAthkarCategoryTitle(context, row.category);
    final String statusText = switch (row.completion) {
      HomeAthkarCompletionState.done => context.l10n.homeAthkarDone,
      HomeAthkarCompletionState.inProgress => context.l10n.homeAthkarRemaining(
        row.remainingCount,
      ),
      HomeAthkarCompletionState.notStarted => context.l10n.homeAthkarNotStarted,
    };

    return HomePrimaryCardPressWrapper(
      child: Semantics(
        button: true,
        label: title,
        value: statusText,
        child: HomeDashboardCard(
          surface: TilawaCardSurface.raised,
          onTap: () => AthkarDetailsRoute(
            categoryId: row.category.id,
            categoryName: title,
            source: 'home_daily_habit',
          ).push(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                athkarCategoryIcon(row.category.icon),
                color: colorScheme.primary,
                size: tokens.iconSizeLarge,
              ),
              SizedBox(width: tokens.spaceMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: tokens.spaceExtraSmall),
                    Text(
                      statusText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
