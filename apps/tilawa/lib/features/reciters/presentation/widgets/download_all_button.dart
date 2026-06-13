import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa/features/reciters/presentation/widgets/reciter_catalog_chrome.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../features/surah/domain/entities/surah_entity.dart';
import '../bloc/reciter_download_bloc.dart';
import '../reciter_semantics_ids.dart';

/// Inline download button designed to sit inside a header
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
    final borderRadius = BorderRadius.circular(
      tokens.resolveRadius(
        family: TilawaRadiusFamily.pill,
        height: tokens.minInteractiveDimension,
      ),
    );
    final Color idleFill = ReciterCatalogChrome.idleFill(colorScheme);
    final Color hairline = ReciterCatalogChrome.hairline(colorScheme, tokens);

    return BlocListener<ReciterDownloadBloc, ReciterDownloadState>(
      listenWhen: (previous, current) => current.shouldShowError(previous),
      listener: (context, state) {
        if (state.isInsufficientStorage) {
          ToastUtils.showErrorToast(
            context.l10n.downloadLowStorageBlocked,
          );
          return;
        }
        final String message = state.isNetworkError
            ? context.l10n.networkError
            : state.errorMessage ?? context.l10n.networkError;
        ToastUtils.showToast(msg: message);
      },
      child: BlocBuilder<ReciterDownloadBloc, ReciterDownloadState>(
        builder: (context, state) {
          final bool isDownloading = state.isDownloadingAll;
          final bool isActive = isDownloading || state.isPending;
          final double progress = state.progress;
          final bool isAllDownloaded = state.isAllDownloaded;
          final Color fill = isAllDownloaded || !isActive
              ? idleFill
              : ReciterCatalogChrome.downloadingFill(colorScheme);
          final EdgeInsetsGeometry chipPadding = chipTokens.inlinePadding.add(
            EdgeInsets.symmetric(
              horizontal: tokens.spaceSmall,
              vertical: tokens.spaceExtraSmall,
            ),
          );

          if (isAllDownloaded) {
            return Semantics(
              identifier:
                  ReciterSemanticsIds.reciterDetailsDownloadAllCompleted,
              child: Container(
                height: tokens.minInteractiveDimension,
                padding: chipPadding,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: hairline,
                    width: chipTokens.borderWidth,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: colorScheme.onSurface,
                      size: chipTokens.inlineIconSize,
                    ),
                    SizedBox(width: tokens.spaceExtraSmall),
                    Text(
                      context.l10n.allDownloaded,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Semantics(
            identifier: isDownloading
                ? ReciterSemanticsIds.reciterDetailsDownloadAllDownloading
                : ReciterSemanticsIds.reciterDetailsDownloadAllIdle,
            child: SizedBox(
              height: tokens.minInteractiveDimension,
              child: Material(
                color: fill,
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
                        StartReciterDownloadAll(
                          reciter: reciter,
                          surahs: surahs,
                        ),
                      );
                    }
                  },
                  borderRadius: borderRadius,
                  child: Container(
                    padding: chipPadding,
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: borderRadius,
                      border: Border.all(
                        color: hairline,
                        width: chipTokens.borderWidth,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isActive) ...[
                          SizedBox(
                            width: chipTokens.inlineIconSize,
                            height: chipTokens.inlineIconSize,
                            child: TilawaLoadingIndicator(
                              strokeWidth: 2,
                              value: isDownloading && progress > 0
                                  ? progress.clamp(0.0, 1.0)
                                  : null,
                              color: colorScheme.onSurface,
                              backgroundColor: colorScheme.onSurface.withValues(
                                alpha: tokens.opacitySubtle,
                              ),
                            ),
                          ),
                          SizedBox(width: tokens.spaceSmall),
                          Text(
                            '${state.downloadedCount}/${state.totalCount}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (isDownloading) ...[
                            SizedBox(width: tokens.spaceExtraSmall),
                            Icon(
                              Icons.pause_rounded,
                              color: colorScheme.onSurface,
                              size: chipTokens.inlineIconSize,
                            ),
                          ],
                        ] else ...[
                          Icon(
                            Icons.download_rounded,
                            color: colorScheme.onSurfaceVariant,
                            size: chipTokens.inlineIconSize,
                          ),
                          SizedBox(width: tokens.spaceExtraSmall),
                          Text(
                            '${state.downloadedCount}/${state.totalCount}',
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
            ),
          );
        },
      ),
    );
  }
}
