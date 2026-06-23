import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/athkar/presentation/athkar_category_presentation.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_state.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_dashboard_card.dart';

/// Three-row daily athkar card with completion state.
class HomeAthkarCompactCard extends StatelessWidget {
  const HomeAthkarCompactCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeAthkarCompactCubit, HomeAthkarCompactState>(
      builder: (context, state) {
        if (state.status == HomeAthkarRowStatus.loading ||
            state.status == HomeAthkarRowStatus.initial) {
          return const HomeDashboardCard(
            surface: TilawaCardSurface.raised,
            child: TilawaLoadingIndicator(centered: false),
          );
        }

        if (state.rows.isEmpty) {
          return const SizedBox.shrink();
        }

        final tokens = context.tokens;
        final colorScheme = Theme.of(context).colorScheme;

        return HomeDashboardCard(
          surface: TilawaCardSurface.raised,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < state.rows.length; index++) ...[
                if (index > 0)
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: tokens.spaceMedium,
                    ),
                    child: TilawaDivider(
                      height: tokens.borderWidthThin,
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                _HomeAthkarCompactRow(row: state.rows[index]),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HomeAthkarCompactRow extends StatelessWidget {
  const _HomeAthkarCompactRow({required this.row});

  final HomeAthkarRowState row;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String title = localizedAthkarCategoryTitle(
      context,
      row.category,
    );
    final String statusText = _statusText(context);

    return Semantics(
      button: true,
      label: title,
      value: statusText,
      child: InkWell(
        onTap: () => AthkarDetailsRoute(
          categoryId: row.category.id,
          categoryName: title,
          source: 'home_compact',
        ).push(context),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceMedium,
            vertical: tokens.spaceSmall,
          ),
          child: Row(
            children: [
              Icon(
                athkarCategoryIcon(row.category.icon),
                color: colorScheme.primary,
                size: tokens.iconSizeSmall,
              ),
              SizedBox(width: tokens.spaceSmall),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                statusText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
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

  String _statusText(BuildContext context) {
    return switch (row.completion) {
      HomeAthkarCompletionState.done => context.l10n.homeAthkarDone,
      HomeAthkarCompletionState.inProgress => context.l10n.homeAthkarRemaining(
        row.remainingCount,
      ),
      HomeAthkarCompletionState.notStarted => context.l10n.homeAthkarNotStarted,
    };
  }
}
