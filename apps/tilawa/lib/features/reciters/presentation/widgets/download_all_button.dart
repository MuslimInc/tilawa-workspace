import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/reciters/presentation/widgets/reciter_catalog_chrome.dart';
import 'package:tilawa/shared/widgets/quran_player_chrome.dart';
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
    context.watch<QuranPlayerChromeNotifier>();
    context.select(
      (AudioPlayerBloc bloc) => (
        bloc.state.shouldShowBottomPlayer,
        bloc.state.currentAudio?.id,
      ),
    );

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

    return BlocListener<ReciterDownloadBloc, ReciterDownloadState>(
      listenWhen: (previous, current) => current.shouldShowError(previous),
      listener: (context, state) {
        if (state.isInsufficientStorage) {
          TilawaFeedback.showToast(
            context,
            message: context.l10n.downloadLowStorageBlocked,
            variant: TilawaFeedbackVariant.error,
          );
          return;
        }
        final String message = state.isNetworkError
            ? context.l10n.networkError
            : state.errorMessage ?? context.l10n.networkError;
        TilawaFeedback.showToast(
          context,
          message: message,
          variant: TilawaFeedbackVariant.error,
        );
      },
      child: BlocBuilder<ReciterDownloadBloc, ReciterDownloadState>(
        builder: (context, state) {
          final bool isDownloading = state.isDownloadingAll;
          final bool isActive = isDownloading || state.isPending;
          final double progress = state.progress;
          final bool isAllDownloaded = state.isAllDownloaded;
          final Color fill = isAllDownloaded || !isActive
              ? ReciterCatalogChrome.controlIdleFill(context, colorScheme)
              : ReciterCatalogChrome.controlDownloadingFill(
                  context,
                  colorScheme,
                );
          final Color hairline = ReciterCatalogChrome.controlBorder(
            context,
            colorScheme,
            tokens,
          );
          final EdgeInsetsGeometry chipPadding = chipTokens.inlinePadding.add(
            EdgeInsets.symmetric(
              horizontal: tokens.spaceSmall,
              vertical: tokens.spaceExtraSmall,
            ),
          );
          final RoundedRectangleBorder chipShape = RoundedRectangleBorder(
            borderRadius: borderRadius,
            side: BorderSide(
              color: hairline,
              width: chipTokens.borderWidth,
            ),
          );

          final Widget chipContent = Padding(
            padding: chipPadding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAllDownloaded) ...[
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
                ] else if (isActive) ...[
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
          );

          if (isAllDownloaded) {
            return Semantics(
              identifier:
                  ReciterSemanticsIds.reciterDetailsDownloadAllCompleted,
              child: Container(
                key: const Key('reciter_details_download_all_button'),
                height: tokens.minInteractiveDimension,
                decoration: ShapeDecoration(
                  color: fill,
                  shape: chipShape,
                ),
                child: chipContent,
              ),
            );
          }

          return Semantics(
            identifier: isDownloading
                ? ReciterSemanticsIds.reciterDetailsDownloadAllDownloading
                : ReciterSemanticsIds.reciterDetailsDownloadAllIdle,
            child: SizedBox(
              height: tokens.minInteractiveDimension,
              child: TilawaInteractiveSurface(
                key: const Key('reciter_details_download_all_button'),
                onTap: state.isPending
                    ? null
                    : () {
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
                haptic: TilawaHaptic.lightImpact,
                borderRadius: borderRadius,
                materialColor: fill,
                materialShape: chipShape,
                child: chipContent,
              ),
            ),
          );
        },
      ),
    );
  }
}
