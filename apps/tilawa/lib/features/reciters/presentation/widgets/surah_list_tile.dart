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
import 'reciter_catalog_chrome.dart';

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
    // Leading badge size matches the reciter avatar (iconSizeLarge + spaceExtraLarge = 48dp).
    final double badgeSize = tokens.iconSizeLarge + tokens.spaceExtraLarge;
    final Color activeFill = ReciterCatalogChrome.activeFill(colorScheme);
    final Color activeOnFill = ReciterCatalogChrome.activeOnFill(colorScheme);
    // Badge bg cycles through the same M3 container palette as the reciter avatar,
    // keyed by surah index so adjacent rows are visually distinct.
    final List<Color> badgePalette = [
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
      colorScheme.surfaceContainerHighest,
    ];
    final List<Color> badgeFgPalette = [
      colorScheme.onPrimaryContainer,
      colorScheme.onSecondaryContainer,
      colorScheme.onTertiaryContainer,
      colorScheme.onSurfaceVariant,
    ];
    final Color idleFill = badgePalette[index % badgePalette.length];
    final Color idleFg = badgeFgPalette[index % badgeFgPalette.length];

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

    void handleTap() {
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
    }

    return Semantics(
      identifier: ReciterSemanticsIds.surahRow(
        surah.formattedId.isNotEmpty ? surah.formattedId : '${index + 1}',
      ),
      button: true,
      child: TilawaCard(
        surface: TilawaCardSurface.flat,
        backgroundColor: isCurrentItem
            ? colorScheme.primaryContainer.withValues(
                alpha: tokens.opacitySubtle * 2,
              )
            : colorScheme.surface,
        borderColor: isCurrentItem ? activeFill : colorScheme.outlineVariant,
        borderWidth: isCurrentItem
            ? tokens.borderWidthThin * 4
            : tokens.borderWidthThin,
        borderRadius: tileRadius,
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceLarge,
          vertical: tokens.spaceLarge,
        ),
        onTap: handleTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Leading: rounded-rect badge — same size & radius family as ReciterCard avatar.
            AnimatedContainer(
              duration: tokens.durationFast,
              width: badgeSize,
              height: badgeSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                // Apply same opacityEmphasis (0.7) dampening as the reciter avatar —
                // keeps container colors soft across all four palette slots.
                color: isCurrentItem
                    ? activeFill
                    : idleFill.withValues(alpha: tokens.opacityEmphasis),
                borderRadius: BorderRadius.circular(tokens.radiusLarge),
                border: Border.all(
                  color: isCurrentItem
                      ? activeFill
                      : idleFg.withValues(alpha: tokens.opacityShadow),
                  width: tokens.borderWidthThin * 2,
                ),
              ),
              child: isCurrentItem
                  ? Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: activeOnFill,
                      size: tokens.iconSizeMedium,
                    )
                  : Text(
                      surah.formattedId.isNotEmpty
                          ? surah.formattedId
                          : '${index + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: idleFg,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
            ),
            SizedBox(width: tokens.spaceMedium),
            // Content block — mirrors ReciterCard's title+subtitle column.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: tokens.spaceExtraSmall,
                children: [
                  Text(
                    surah.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
            // Trailing: download only — play state is shown on the leading badge.
            DownloadButton(
              url: surah.id,
              surahTitle: surah.name,
              reciterName: reciterName,
              reciterId: reciterId,
              catalogChrome: true,
              initialIsDownloaded: surah.isDownloaded,
              initialIsDownloading: surah.isDownloading,
              initialProgress: surah.downloadProgress,
              identifier: ReciterSemanticsIds.surahDownloadButton(
                surah.formattedId.isNotEmpty
                    ? surah.formattedId
                    : '${index + 1}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showSurahOptionsSheet(BuildContext context, SurahEntity surah) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final int surahNumber = int.tryParse(surah.formattedId) ?? (index + 1);

    showTilawaModalBottomSheet<void>(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: TilawaBottomSheetScaffold.modalShape(context),
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
                  color: colorScheme.onSurfaceVariant,
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
                  color: colorScheme.onSurfaceVariant,
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
