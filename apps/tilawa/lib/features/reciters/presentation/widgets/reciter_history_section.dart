import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Compact horizontal carousel of recently listened surahs for
/// quick resume playback. Uses chip-style cards to minimize
/// vertical space.
class ReciterHistorySection extends StatelessWidget {
  const ReciterHistorySection({
    super.key,
    required this.historyList,
    required this.onPlay,
  });

  final List<HistoryEntity> historyList;
  final Function(HistoryEntity) onPlay;

  @override
  Widget build(BuildContext context) {
    if (historyList.isEmpty) return const SizedBox.shrink();

    final displayList = historyList.take(5).toList();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
          child: Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: tokens.iconSizeMedium,
                color: colorScheme.primary,
              ),
              SizedBox(width: tokens.spaceSmall),
              Text(
                context.l10n.continueListening,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spaceSmall),
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
            scrollDirection: Axis.horizontal,
            itemCount: displayList.length,
            separatorBuilder: (_, _) => SizedBox(width: tokens.spaceSmall),
            itemBuilder: (context, index) {
              final history = displayList[index];
              return _HistoryChip(
                history: history,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onPlay(history);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Compact chip-style card showing surah name with a play/check
/// icon and progress percentage.
class _HistoryChip extends StatelessWidget {
  const _HistoryChip({required this.history, required this.onTap});

  final HistoryEntity history;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;
    final chipTokens = theme.componentTokens.chip;
    final bool isComplete = history.progress >= 1.0;
    final int percent = (history.progress * 100).clamp(0, 100).toInt();
    final String displayName = context.isArabic
        ? history.surahName
        : history.surahNameEn;

    final BorderRadius borderRadius = .circular(chipTokens.pillRadius);

    return Material(
      color: isComplete
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerLow,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          padding: .symmetric(
            horizontal: tokens.spaceMedium,
            vertical: tokens.spaceSmall,
          ),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: .all(
              color: isComplete
                  ? colorScheme.primary.withValues(alpha: 0.34)
                  : colorScheme.outlineVariant.withValues(
                      alpha: tokens.opacityMedium,
                    ),
              width: chipTokens.borderWidth,
            ),
          ),
          child: Row(
            mainAxisSize: .min,
            children: [
              Icon(
                isComplete
                    ? Icons.check_circle_rounded
                    : Icons.play_circle_fill_rounded,
                color: isComplete
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.primary,
                size: tokens.iconSizeMedium,
              ),
              SizedBox(width: tokens.spaceSmall),
              Text(
                displayName,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isComplete
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                ),
              ),
              if (!isComplete && percent >= 5) ...[
                SizedBox(width: tokens.spaceSmall),
                Text(
                  '$percent%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: .w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
