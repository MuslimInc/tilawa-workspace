import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.history_rounded, size: 16, color: theme.primaryColor),
              SizedBox(width: 6),
              Text(
                context.l10n.continueListening,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: displayList.length,
            separatorBuilder: (_, _) => SizedBox(width: 8),
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
    final bool isComplete = history.progress >= 1.0;
    final int percent = (history.progress * 100).clamp(0, 100).toInt();
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final String displayName = isArabic
        ? history.surahName
        : history.surahNameEn;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isComplete
              ? theme.primaryColor.withValues(alpha: 0.08)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isComplete
                ? theme.primaryColor.withValues(alpha: 0.3)
                : theme.dividerColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isComplete
                  ? Icons.check_circle_rounded
                  : Icons.play_circle_fill_rounded,
              color: theme.primaryColor,
              size: 18,
            ),
            SizedBox(width: 6),
            Text(
              displayName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: isComplete
                    ? theme.primaryColor
                    : theme.textTheme.bodyLarge?.color,
              ),
            ),
            if (!isComplete && percent >= 5) ...[
              SizedBox(width: 6),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: theme.primaryColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
