import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../cubit/tasbeeh_cubit.dart';
import '../../cubit/tasbeeh_state.dart';
import 'tasbeeh_layout_widgets.dart';

class TasbeehHistoryView extends StatelessWidget {
  const TasbeehHistoryView({
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
    final double shadowScrollInset =
        tokens.blurShadow + tokens.shadowOffsetSmall.dy;

    return TasbeehContentBounds(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.savedDhikr.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.spaceLarge,
                tokens.spaceLarge,
                tokens.spaceLarge,
                0,
              ),
              child: Text(
                context.l10n.tasbeehChooseSavedDhikr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          Expanded(
            child: state.savedDhikr.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(tokens.spaceLarge),
                    child: TilawaIllustratedState(
                      visual: const TilawaStateVisual(
                        icon: Icons.history_toggle_off_rounded,
                        tone: TilawaStateVisualTone.tertiary,
                      ),
                      title: context.l10n.tasbeehHistoryEmpty,
                      semanticLabel: context.l10n.tasbeehHistoryEmpty,
                    ),
                  )
                : ListView.separated(
                    clipBehavior: Clip.none,
                    padding: EdgeInsets.fromLTRB(
                      tokens.spaceLarge,
                      shadowScrollInset,
                      tokens.spaceLarge,
                      shadowScrollInset + tokens.spaceLarge,
                    ),
                    itemCount: state.savedDhikr.length,
                    separatorBuilder: (_, _) =>
                        SizedBox(height: shadowScrollInset),
                    itemBuilder: (context, index) {
                      final item = state.savedDhikr[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TilawaCard(
                              onTap: () =>
                                  cubit.selectDhikrAndStartCounting(item.id),
                              borderRadius: tokens.radiusLarge,
                              borderColor: theme.colorScheme.primary
                                  .withValues(alpha: tokens.opacitySubtle),
                              backgroundColor: theme.colorScheme.surface
                                  .withValues(alpha: tokens.opacityGlass),
                              child: Row(
                                children: [
                                  TilawaIconBox(
                                    icon: Icons.radio_button_checked_rounded,
                                    iconColor: theme.colorScheme.primary,
                                    backgroundColor: theme.colorScheme.primary
                                        .withValues(
                                          alpha: tokens.opacitySubtle,
                                        ),
                                    borderRadius: tokens.radiusLarge,
                                  ),
                                  SizedBox(width: tokens.spaceMedium),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.text,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        SizedBox(
                                          height: tokens.spaceExtraSmall,
                                        ),
                                        Text(
                                          context.l10n.tasbeehCurrentTarget(
                                            item.targetCount,
                                          ),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: tokens.spaceSmall),
                          TilawaIconActionButton(
                            icon: Icons.delete_outline_rounded,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHigh,
                            onTap: () async {
                              final shouldDelete = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) =>
                                    TasbeehDeleteConfirmationDialog(
                                      tasbeehText: item.text,
                                    ),
                              );
                              if (shouldDelete == true) {
                                await cubit.removeDhikr(item.id);
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
