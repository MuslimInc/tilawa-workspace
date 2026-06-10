import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../cubit/tasbeeh_cubit.dart';
import '../../cubit/tasbeeh_state.dart';
import 'tasbeeh_layout_widgets.dart';
import 'tasbeeh_saved_dhikr_list.dart';

class TasbeehHomeView extends StatelessWidget {
  const TasbeehHomeView({
    super.key,
    required this.cubit,
    required this.state,
  });

  final TasbeehCubit cubit;
  final TasbeehState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return TasbeehContentBounds(
      alignTop: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLarge,
          tokens.spaceMedium,
          tokens.spaceLarge,
          tokens.spaceMedium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.tasbeehSelectOrCreatePrompt,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: tokens.spaceMedium),
            _QuickCountCard(
              count: state.ephemeralCount,
              onTap: cubit.startQuickCount,
            ),
            SizedBox(height: tokens.spaceLarge),
            Text(
              context.l10n.tasbeehChooseSavedDhikr,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: tokens.spaceMedium),
            if (state.savedDhikr.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.spaceLarge),
                child: TilawaIllustratedState(
                  visual: const TilawaStateVisual(
                    icon: Icons.history,
                    tone: TilawaStateVisualTone.tertiary,
                  ),
                  title: context.l10n.tasbeehHistoryEmpty,
                  semanticLabel: context.l10n.tasbeehHistoryEmpty,
                ),
              )
            else
              TasbeehSavedDhikrList(
                cubit: cubit,
                savedDhikr: state.savedDhikr,
              ),
          ],
        ),
      ),
    );
  }
}

class TasbeehHomeActions extends StatelessWidget {
  const TasbeehHomeActions({super.key, required this.cubit});

  final TasbeehCubit cubit;

  @override
  Widget build(BuildContext context) {
    return TilawaButton(
      text: context.l10n.tasbeehAddNewOptionTitle,
      leadingIcon: const Icon(Icons.add_rounded),
      variant: TilawaButtonVariant.primary,
      isFullWidth: true,
      onPressed: cubit.showCreateView,
    );
  }
}

class _QuickCountCard extends StatelessWidget {
  const _QuickCountCard({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return TilawaCard(
      onTap: onTap,
      borderRadius: tokens.radiusLarge,
      surface: TilawaCardSurface.raised,
      backgroundColor: colorScheme.surface,
      child: Row(
        children: [
          TilawaIconBox(
            icon: Icons.touch_app_rounded,
            iconColor: colorScheme.primary,
            backgroundColor: colorScheme.primary.withValues(
              alpha: tokens.opacitySubtle,
            ),
            borderRadius: tokens.radiusLarge,
          ),
          SizedBox(width: tokens.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.tasbeehQuickCountTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: tokens.spaceExtraSmall),
                Text(
                  context.l10n.tasbeehQuickCountSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (count > 0) ...[
            SizedBox(width: tokens.spaceSmall),
            TilawaStatusChip(
              label: '$count',
              icon: Icons.radio_button_checked_rounded,
            ),
          ],
          SizedBox(width: tokens.spaceSmall),
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
