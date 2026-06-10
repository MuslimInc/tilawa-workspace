import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../domain/entities/tasbeeh_dhikr.dart';
import '../../cubit/tasbeeh_cubit.dart';
import 'tasbeeh_layout_widgets.dart';

class TasbeehSavedDhikrList extends StatelessWidget {
  const TasbeehSavedDhikrList({
    super.key,
    required this.cubit,
    required this.savedDhikr,
  });

  final TasbeehCubit cubit;
  final List<TasbeehDhikr> savedDhikr;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final double shadowScrollInset =
        tokens.blurShadow + tokens.shadowOffsetSmall.dy;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      clipBehavior: Clip.none,
      padding: EdgeInsets.only(bottom: shadowScrollInset),
      itemCount: savedDhikr.length,
      separatorBuilder: (_, _) => SizedBox(height: tokens.spaceMedium),
      itemBuilder: (context, index) {
        final item = savedDhikr[index];
        return _TasbeehSavedDhikrTile(
          item: item,
          onOpen: () => cubit.selectDhikrAndStartCounting(item.id),
          onDelete: () async {
            final shouldDelete = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => TasbeehDeleteConfirmationDialog(
                tasbeehText: item.text,
              ),
            );
            if (shouldDelete == true) {
              await cubit.removeDhikr(item.id);
            }
          },
        );
      },
    );
  }
}

/// One raised surface: tappable body + flush delete strip (no sibling gap).
class _TasbeehSavedDhikrTile extends StatelessWidget {
  const _TasbeehSavedDhikrTile({
    required this.item,
    required this.onOpen,
    required this.onDelete,
  });

  final TasbeehDhikr item;
  final VoidCallback onOpen;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final bool isComplete =
        item.targetCount > 0 && item.count >= item.targetCount;
    final BorderRadius borderRadius = BorderRadius.circular(tokens.radiusLarge);

    return TilawaCard(
      borderRadius: tokens.radiusLarge,
      surface: TilawaCardSurface.raised,
      padding: EdgeInsets.zero,
      backgroundColor: colorScheme.surface.withValues(
        alpha: tokens.opacityGlass,
      ),
      borderColor: colorScheme.primary.withValues(alpha: tokens.opacitySubtle),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onOpen,
                    child: Padding(
                      padding: theme.componentTokens.card.padding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: tokens.spaceExtraSmall),
                          Text(
                            context.l10n.tasbeehProgressLabel(
                              item.count,
                              item.targetCount,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isComplete
                                  ? colorScheme.tertiary
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              VerticalDivider(
                width: tokens.borderWidthThin,
                thickness: tokens.borderWidthThin,
                color: colorScheme.outlineVariant.withValues(
                  alpha: tokens.opacityMedium,
                ),
              ),
              Material(
                color: colorScheme.surfaceContainerHigh,
                child: Center(
                  child: TilawaIconActionButton(
                    icon: Icons.delete_outline_rounded,
                    backgroundColor: Colors.transparent,
                    onTap: onDelete,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
