import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

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
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;
    final chipTokens = theme.componentTokens.chip;
    final borderRadius = BorderRadius.circular(chipTokens.pillRadius);

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
              padding: chipTokens.compactPadding.add(
                EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: borderRadius,
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(
                    alpha: tokens.opacityMedium,
                  ),
                  width: chipTokens.borderWidth,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: chipTokens.compactIconSize,
                  ),
                  SizedBox(width: tokens.spaceExtraSmall),
                  Text(
                    context.l10n.allDownloaded,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
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
          child: Material(
            color: isDownloading
                ? colorScheme.primaryContainer.withValues(alpha: 0.74)
                : colorScheme.surfaceContainerLow,
            borderRadius: borderRadius,
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
              borderRadius: borderRadius,
              child: Container(
                padding: chipTokens.compactPadding.add(
                  EdgeInsets.symmetric(
                    horizontal: tokens.spaceSmall,
                    vertical: tokens.spaceExtraSmall,
                  ),
                ),
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: isDownloading
                        ? colorScheme.primary.withValues(alpha: 0.5)
                        : colorScheme.outlineVariant.withValues(
                            alpha: tokens.opacityMedium,
                          ),
                    width: chipTokens.borderWidth,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDownloading) ...[
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: TilawaLoadingIndicator(
                          centered: false,
                          strokeWidth: 2,
                          value: progress,
                          color: colorScheme.primary,
                          backgroundColor: colorScheme.primaryContainer,
                        ),
                      ),
                      SizedBox(width: tokens.spaceSmall),
                      Text(
                        '${state.downloadedCount}/${state.totalCount}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: tokens.spaceExtraSmall),
                      Icon(
                        Icons.pause_rounded,
                        color: colorScheme.primary,
                        size: chipTokens.compactIconSize,
                      ),
                    ] else ...[
                      Icon(
                        Icons.download_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: chipTokens.compactIconSize,
                      ),
                      SizedBox(width: tokens.spaceExtraSmall),
                      Text(
                        _buildLabel(context, state, isDownloading, progress),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
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
