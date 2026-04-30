import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

import '../../../../features/surah/domain/entities/surah_entity.dart';
import '../bloc/reciter_download_bloc.dart';
import '../reciter_semantics_ids.dart';

/// Compact download button designed to sit inline inside a header
/// row next to the surah count label.
class DownloadAllButton extends StatelessWidget {
  const DownloadAllButton({
    super.key,
    required this.reciter,
    required this.surahs,
  });
  final ReciterEntity reciter;
  final List<SurahEntity> surahs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<ReciterDownloadBloc, ReciterDownloadState>(
      listenWhen: (previous, current) => current.shouldShowError(previous),
      listener: (context, state) {
        if (state.isNetworkError) {
          ToastUtils.showToast(msg: context.l10n.networkError);
        }
      },
      builder: (context, state) {
        final bool isDownloading = state.isDownloadingAll;
        final double progress = state.progress;
        final bool isAllDownloaded = state.isAllDownloaded;

        // All downloaded — small check badge
        if (isAllDownloaded) {
          return Semantics(
            identifier: ReciterSemanticsIds.reciterDetailsDownloadAllCompleted,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.primaryColor,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    context.l10n.allDownloaded,
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Download / Downloading — compact pill
        return Semantics(
          identifier: isDownloading
              ? ReciterSemanticsIds.reciterDetailsDownloadAllDownloading
              : ReciterSemanticsIds.reciterDetailsDownloadAllIdle,
          child: InkWell(
            key: const Key('reciter_details_download_all_button'),
            onTap: () {
              if (state.isPending) return;
              HapticFeedback.lightImpact();
              if (isDownloading) {
                context.read<ReciterDownloadBloc>().add(
                  CancelReciterDownloadAll(reciterName: reciter.name),
                );
              } else {
                context.read<ReciterDownloadBloc>().add(
                  StartReciterDownloadAll(reciter: reciter, surahs: surahs),
                );
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDownloading
                    ? theme.primaryColor.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDownloading
                      ? theme.primaryColor.withValues(alpha: 0.6)
                      : theme.dividerColor.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isDownloading) ...[
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: progress,
                        color: theme.primaryColor,
                        backgroundColor: theme.primaryColor.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      '${state.downloadedCount}/${state.totalCount}',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.pause_rounded,
                      color: theme.primaryColor,
                      size: 14,
                    ),
                  ] else ...[
                    Icon(
                      Icons.download_rounded,
                      color: theme.textTheme.bodyMedium?.color,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      _buildLabel(context, state, isDownloading, progress),
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _buildLabel(
    BuildContext context,
    ReciterDownloadState state,
    bool isDownloading,
    double progress,
  ) {
    // Always use compact fraction format for inline display
    return '${state.downloadedCount}/${state.totalCount}';
  }
}
