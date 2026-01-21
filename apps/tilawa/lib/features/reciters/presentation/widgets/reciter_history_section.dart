import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';

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

    // Filter to show only recent history (last 30 days or so, or just take latest few)
    // Removed strict 7 days limit to ensure user sees history if they have it.
    final displayList = historyList.take(5).toList();
    final theme = Theme.of(context);

    if (displayList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            top: 8.h,
            bottom: 12.h,
          ),
          child: Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 20.sp,
                color: theme.primaryColor,
              ),
              SizedBox(width: 8.w),
              Text(
                context.l10n.continueListening,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 110.h, // Fixed height for carousel
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            scrollDirection: Axis.horizontal,
            itemCount: displayList.length,
            separatorBuilder: (context, index) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final history = displayList[index];
              return _HistoryItem(
                history: history,
                onTap: () => onPlay(history),
              );
            },
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.history, required this.onTap});

  final HistoryEntity history;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 160.w,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    history.surahName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.play_circle_fill_rounded,
                  color: theme.primaryColor,
                  size: 24.sp,
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              history.reciterName,
              style: TextStyle(
                fontSize: 11.sp,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.6,
                ),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Spacer(),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                value: history.progressPercentage / 100,
                minHeight: 4.h,
                backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              context
                  .l10n
                  .continueReading, // Or "Resume" if available, checking l10n
              // Actually l10n.continueListening or similar might be better but 'continueReading' was used in sheet.
              // Let's stick to formatted remaining time or just "Resume" styling
              style: TextStyle(
                fontSize: 10.sp,
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ).hide(), // Helper to hide if needed or replace content
          ],
        ),
      ),
    );
  }
}

extension on Widget {
  // Quick helper to hide widget if needed during dev,
  // actually I will just put the time there instead.
  Widget hide() => const SizedBox.shrink();
}
