import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../domain/entities/tasbeeh_dhikr.dart';
import '../../cubit/tasbeeh_cubit.dart';
import 'tasbeeh_layout_widgets.dart';
import 'tasbeeh_saved_dhikr_tile_content.dart';

class TasbeehSavedDhikrGrid extends StatelessWidget {
  const TasbeehSavedDhikrGrid({
    super.key,
    required this.cubit,
    required this.savedDhikr,
  });

  final TasbeehCubit cubit;
  final List<TasbeehDhikr> savedDhikr;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final int columns = context.isAtLeastMedium ? 3 : 2;
    final double shadowScrollInset =
        tokens.blurShadow + tokens.shadowOffsetSmall.dy;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      clipBehavior: Clip.none,
      padding: EdgeInsets.only(bottom: shadowScrollInset),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: tokens.spaceMedium,
        crossAxisSpacing: tokens.spaceMedium,
        childAspectRatio: 1.45,
      ),
      itemCount: savedDhikr.length,
      itemBuilder: (context, index) {
        final item = savedDhikr[index];
        return _TasbeehGridCell(
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

class _TasbeehGridCell extends StatelessWidget {
  const _TasbeehGridCell({
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

    return TilawaCard(
      borderRadius: tokens.radiusLarge,
      surface: TilawaCardSurface.raised,
      padding: EdgeInsets.zero,
      backgroundColor: colorScheme.surface.withValues(
        alpha: tokens.opacityGlass,
      ),
      borderColor: colorScheme.primary.withValues(alpha: tokens.opacitySubtle),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onOpen,
                  onLongPress: onDelete,
                  child: Padding(
                    padding: theme.componentTokens.card.padding,
                    child: TasbeehSavedDhikrTileContent(
                      item: item,
                      compact: true,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
