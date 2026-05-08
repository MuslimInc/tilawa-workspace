import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/downloads/presentation/widgets/download_button.dart';
import 'package:tilawa/features/surah/domain/entities/surah_entity.dart';
import 'package:tilawa/router/router.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../reciter_semantics_ids.dart';

class SurahListTile extends StatelessWidget {
  const SurahListTile({
    super.key,
    required this.surah,
    required this.index,
    required this.reciterName,
    required this.reciterId,
    required this.onTap,
  });

  final SurahEntity surah;
  final int index;
  final String reciterName;
  final int reciterId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final double tileRadius = tokens.radiusLarge;
    final double badgeSize = tokens.iconSizeLargePlus;
    final Color activeColor = colorScheme.primary;
    final Color activeForeground = colorScheme.onPrimary;

    // Combine selectors to reduce overhead and subscription count
    final (bool isPlaying, bool isCurrentItem) = context
        .select<AudioPlayerBloc, (bool, bool)>((bloc) {
          final AudioEntity? currentAudio = bloc.state.currentAudio;
          final PlaybackStateEntity? playbackState = bloc.state.playbackState;
          final bool shouldShowPlayer = bloc.state.shouldShowBottomPlayer;

          final bool isCurrent =
              shouldShowPlayer &&
              (currentAudio?.id == surah.id ||
                  currentAudio?.url == surah.audio.url);

          final bool playing = isCurrent && (playbackState?.isPlaying ?? false);

          return (playing, isCurrent);
        });

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tileRadius),
        border: isCurrentItem
            ? BorderDirectional(
                start: BorderSide(
                  color: activeColor,
                  width: tokens.borderWidthThin * 6,
                ),
              )
            : Border.all(
                color: colorScheme.outlineVariant.withValues(
                  alpha: tokens.opacitySubtle,
                ),
                width: tokens.borderWidthThin,
              ),
      ),
      child: Material(
        color: isCurrentItem
            ? colorScheme.primaryContainer.withValues(alpha: 0.34)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(tileRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(tileRadius),
          onLongPress: () => showSurahOptionsSheet(context, surah),
          onTap: () {
            if (isCurrentItem) {
              if (isPlaying) {
                context.read<AudioPlayerBloc>().add(
                  const AudioPlayerEvent.pauseAudio(),
                );
              } else {
                context.read<AudioPlayerBloc>().add(
                  const AudioPlayerEvent.playAudio(),
                );
              }
            } else {
              onTap();
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceLarge,
              vertical: tokens.spaceMedium + tokens.spaceTiny,
            ),
            child: Row(
              children: [
                Container(
                  width: badgeSize,
                  height: badgeSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCurrentItem
                        ? activeColor
                        : colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(tokens.radiusMedium),
                    boxShadow: isCurrentItem
                        ? [
                            BoxShadow(
                              color: activeColor.withValues(
                                alpha: tokens.opacitySubtle * 2,
                              ),
                              blurRadius: tokens.blurGlass / 2,
                              offset: tokens.shadowOffsetSmall,
                            ),
                          ]
                        : null,
                  ),
                  child: isCurrentItem
                      ? Icon(
                          Icons.graphic_eq_rounded,
                          color: activeForeground,
                          size: tokens.iconSizeMedium,
                        )
                      : Text(
                          surah.formattedId.isNotEmpty
                              ? surah.formattedId
                              : '${index + 1}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                SizedBox(width: tokens.spaceMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        surah.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isCurrentItem
                              ? activeColor
                              : colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: tokens.spaceExtraSmall),
                      Text(
                        surah.reciterName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DownloadButton(
                      url: surah.id,
                      surahTitle: surah.name,
                      reciterName: reciterName,
                      reciterId: reciterId,
                      initialIsDownloaded: surah.isDownloaded,
                      initialIsDownloading: surah.isDownloading,
                      initialProgress: surah.downloadProgress,
                      identifier: ReciterSemanticsIds.surahDownloadButton(
                        surah.formattedId.isNotEmpty
                            ? surah.formattedId
                            : '${index + 1}',
                      ),
                    ),
                    SizedBox(width: tokens.spaceSmall),
                    AnimatedContainer(
                      duration: tokens.durationFast,
                      width: badgeSize,
                      height: badgeSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrentItem
                            ? activeColor
                            : colorScheme.primaryContainer,
                        boxShadow: isCurrentItem
                            ? [
                                BoxShadow(
                                  color: activeColor.withValues(
                                    alpha: tokens.opacitySubtle * 2,
                                  ),
                                  blurRadius: tokens.blurGlass / 2,
                                  offset: tokens.shadowOffsetSmall,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        isCurrentItem && isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: isCurrentItem
                            ? activeForeground
                            : colorScheme.onPrimaryContainer,
                        size: tokens.iconSizeLarge,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showSurahOptionsSheet(BuildContext context, SurahEntity surah) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final int surahNumber = int.tryParse(surah.formattedId) ?? (index + 1);

    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.radiusExtraLarge),
        ),
      ),
      builder: (sheetContext) {
        final bottomPadding = sheetContext.floatingBottomPadding;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: tokens.spaceMedium),
              const TilawaSheetHandle(),
              Text(
                surah.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: tokens.spaceSmall),
              const TilawaDivider(),
              ListTile(
                leading: Icon(
                  Icons.menu_book_rounded,
                  color: colorScheme.primary,
                ),
                title: Text(context.l10n.quranReader),
                subtitle: Text(context.l10n.continueReading),
                onTap: () {
                  Navigator.pop(sheetContext);
                  QuranReaderRoute(surahNumber: surahNumber).push(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.bookmark_outline_rounded,
                  color: colorScheme.primary,
                ),
                title: Text(context.l10n.addBookmark),
                onTap: () {
                  Navigator.pop(sheetContext);
                  const BookmarksRoute().push(context);
                },
              ),
              SizedBox(height: tokens.spaceLarge),
            ],
          ),
        );
      },
    );
  }
}

class SkeletonSurahListTile extends StatelessWidget {
  const SkeletonSurahListTile({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    return Padding(
      padding: EdgeInsets.all(tokens.spaceMedium),
      child: Row(
        children: [
          TilawaSkeletonBlock(
            width: tokens.iconSizeExtraLarge,
            height: tokens.iconSizeExtraLarge,
            shape: TilawaSkeletonShape.rounded,
          ),
          SizedBox(width: tokens.spaceLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const TilawaSkeletonBlock(width: 120, height: 16),
                SizedBox(height: tokens.spaceSmall),
                const TilawaSkeletonBlock(width: 80, height: 12),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TilawaSkeletonBlock(
                width: tokens.iconSizeLargePlus,
                height: tokens.iconSizeLargePlus,
                borderRadius: tokens.radiusMedium,
              ),
              SizedBox(width: tokens.spaceMedium),
              TilawaSkeletonBlock(
                width: tokens.iconSizeLargePlus,
                height: tokens.iconSizeLargePlus,
                borderRadius: tokens.radiusMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
