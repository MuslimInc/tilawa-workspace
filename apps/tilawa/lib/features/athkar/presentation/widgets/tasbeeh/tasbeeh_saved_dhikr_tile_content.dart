import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../domain/entities/tasbeeh_dhikr.dart';

class TasbeehSavedDhikrTileContent extends StatelessWidget {
  const TasbeehSavedDhikrTileContent({
    super.key,
    required this.item,
    this.compact = false,
  });

  final TasbeehDhikr item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final bool isComplete =
        item.targetCount > 0 && item.count >= item.targetCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.text,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style:
                    (compact
                            ? theme.textTheme.titleSmall
                            : theme.textTheme.titleMedium)
                        ?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
              ),
            ),
            if (item.reminderEnabled) ...[
              SizedBox(width: tokens.spaceExtraSmall),
              Icon(
                Icons.notifications_active_rounded,
                size: tokens.iconSizeSmall,
                color: colorScheme.primary,
                semanticLabel: context.l10n.tasbeehReminderEnabledLabel,
              ),
            ],
          ],
        ),
        SizedBox(height: tokens.spaceExtraSmall),
        Text(
          context.l10n.tasbeehProgressLabel(item.count, item.targetCount),
          style: theme.textTheme.bodySmall?.copyWith(
            color: isComplete
                ? colorScheme.tertiary
                : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
