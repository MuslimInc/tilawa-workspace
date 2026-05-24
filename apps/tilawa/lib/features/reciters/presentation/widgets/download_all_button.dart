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
    final borderRadius = BorderRadius.circular(chipTokens.pillRadius);
    final Color idleFill = ReciterCatalogChrome.idleFill(colorScheme);
    final Color hairline = ReciterCatalogChrome.hairline(colorScheme, tokens);

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

        if (isAllDownloaded) {
          return Semantics(
            identifier: ReciterSemanticsIds.reciterDetailsDownloadAllCompleted,
            child: Container(
              padding: chipTokens.inlinePadding.add(
                EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
              ),
              decoration: BoxDecoration(
                color: idleFill,
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
          child: Material(
            color: isDownloading
                ? ReciterCatalogChrome.activeRowFill(colorScheme)
                : colorScheme.surface,
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
                padding: chipTokens.inlinePadding.add(
                  EdgeInsets.symmetric(
                    horizontal: tokens.spaceSmall,
                    vertical: tokens.spaceExtraSmall,
                  ),
                ),
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: hairline,
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
                          color: colorScheme.onSurface,
                          backgroundColor: idleFill,
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
                      SizedBox(width: tokens.spaceExtraSmall),
                      Icon(
                        Icons.pause_rounded,
                        color: colorScheme.onSurface,
                        size: chipTokens.inlineIconSize,
                      ),
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
        );
      },
    );
  }
}
