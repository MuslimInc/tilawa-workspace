import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../audio_player/presentation/bloc/audio_player_bloc.dart';
import '../../domain/entities/download_item.dart';
import '../bloc/downloads_bloc.dart';
import 'download_item_card.dart';

class ReciterDownloadsSection extends StatefulWidget {
  const ReciterDownloadsSection({
    super.key,
    required this.reciterName,
    required this.downloadsByNarrative,
  });

  final String reciterName;
  final Map<String, List<DownloadItem>> downloadsByNarrative;

  @override
  State<ReciterDownloadsSection> createState() =>
      _ReciterDownloadsSectionState();
}

class _ReciterDownloadsSectionState extends State<ReciterDownloadsSection> {
  bool _isExpanded = false;

  // Get all downloads (flatten map)
  List<DownloadItem> get _allDownloads {
    return widget.downloadsByNarrative.values
        .expand((downloads) => downloads)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<DownloadItem> downloads = _allDownloads;
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shadowColor: Colors.transparent,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(
            alpha: tokens.opacityMedium,
          ),
          width: tokens.borderWidthThin,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReciterHeader(context, downloads),
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0, width: double.infinity),
            secondChild: Column(
              children: [
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(
                    alpha: tokens.opacityMedium,
                  ),
                ),
                _buildDownloadsList(context),
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildReciterHeader(
    BuildContext context,
    List<DownloadItem> downloads,
  ) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: Row(
          children: [
            // Reciter Avatar
            Container(
              padding: EdgeInsets.all(tokens.spaceTiny),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withValues(
                    alpha: tokens.opacitySubtle,
                  ),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  widget.reciterName.isNotEmpty
                      ? widget.reciterName[0].toUpperCase()
                      : 'R',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: tokens.spaceLarge),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.reciterName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: tokens.spaceExtraSmall),
                  Text(
                    '${downloads.length} ${context.l10n.surahs}${widget.downloadsByNarrative.length > 1 ? " • ${widget.downloadsByNarrative.length} narratives" : ""}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_hasCompletedDownloads())
                  BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
                    buildWhen: (previous, current) =>
                        previous.currentAudio != current.currentAudio ||
                        previous.isPlaying != current.isPlaying,
                    builder: (context, audioState) {
                      final bool isPlayingFromThisReciter =
                          _isPlayingFromThisReciter(audioState);
                      final bool isPlaying =
                          isPlayingFromThisReciter &&
                          (audioState.playbackState?.isPlaying ?? false);

                      return IconButton.filledTonal(
                        style: IconButton.styleFrom(padding: EdgeInsets.zero),
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 20,
                        ),
                        onPressed: () =>
                            _handlePlayAllPlayPause(context, audioState),
                        tooltip: isPlaying
                            ? context.l10n.pauseAll
                            : context.l10n.playAll,
                      );
                    },
                  ),
                SizedBox(width: tokens.spaceExtraSmall),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(tokens.radiusMedium),
                  ),
                  onSelected: (value) {
                    if (value == 'delete_all') {
                      _showDeleteReciterDialog(context);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete_all',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: colorScheme.error,
                            size: tokens.iconSizeMedium,
                          ),
                          SizedBox(width: tokens.spaceMedium),
                          Text(
                            context.l10n.deleteAll,
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadsList(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    if (widget.downloadsByNarrative.length == 1) {
      // Single narrative: just show the list
      final List<DownloadItem> downloads =
          widget.downloadsByNarrative.values.first;
      return Column(
        children: downloads.asMap().entries.map((entry) {
          final int index = entry.key;
          final DownloadItem download = entry.value;
          return Column(
            children: [
              DownloadItemCard(
                download: download,
                onDelete: () {
                  context.read<DownloadsBloc>().add(
                    DeleteDownloadEvent(downloadId: download.id),
                  );
                },
              ),
              if (index != downloads.length - 1)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
                  child: TilawaDivider(
                    height: 1,
                    color: colorScheme.outlineVariant.withValues(
                      alpha: tokens.opacitySubtle,
                    ),
                  ),
                ),
            ],
          );
        }).toList(),
      );
    }

    // Multiple narratives: Show header for each narrative
    return Column(
      children: widget.downloadsByNarrative.entries.map((entry) {
        final String narrativeName = entry.key;
        final List<DownloadItem> narrativeDownloads = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Narrative Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceLarge,
                vertical: tokens.spaceMedium,
              ),
              color: colorScheme.surfaceContainerLowest,
              child: Text(
                narrativeName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            // Downloads for this narrative
            ...narrativeDownloads.asMap().entries.map((downloadEntry) {
              final int index = downloadEntry.key;
              final DownloadItem download = downloadEntry.value;
              return Column(
                children: [
                  DownloadItemCard(
                    download: download,
                    onDelete: () {
                      context.read<DownloadsBloc>().add(
                        DeleteDownloadEvent(downloadId: download.id),
                      );
                    },
                  ),
                  // Show divider unless it's the last item in this narrative
                  if (index != narrativeDownloads.length - 1)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.spaceLarge,
                      ),
                      child: TilawaDivider(
                        height: 1,
                        color: colorScheme.outlineVariant.withValues(
                          alpha: tokens.opacitySubtle,
                        ),
                      ),
                    ),
                ],
              );
            }),
            // Divider between narrative sections (except after the last one)
            if (entry.key != widget.downloadsByNarrative.keys.last)
              TilawaDivider(
                height: 1,
                thickness: 4,
                color: colorScheme.outlineVariant.withValues(
                  alpha: tokens.opacitySubtle,
                ),
              ),
          ],
        );
      }).toList(),
    );
  }

  void _showDeleteReciterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteAll),
        content: Text(
          AppLocalizations.of(
            context,
          )!.deleteAllDownloadsConfirmation(widget.reciterName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<DownloadsBloc>().add(
                DeleteReciterDownloads(reciterName: widget.reciterName),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(context.l10n.deleteAll),
          ),
        ],
      ),
    );
  }

  /// Check if there are any completed downloads
  bool _hasCompletedDownloads() {
    return _allDownloads.any(
      (download) => download.status == DownloadStatus.completed,
    );
  }

  /// Check if any download from this reciter is currently playing
  bool _isPlayingFromThisReciter(AudioPlayerState audioState) {
    final AudioEntity? currentAudio = audioState.currentAudio;
    if (currentAudio == null) {
      return false;
    }

    // Check if the current audio entity is from this reciter
    return currentAudio.artist == widget.reciterName;
  }

  /// Handle play all/pause all button press
  void _handlePlayAllPlayPause(
    BuildContext context,
    AudioPlayerState audioState,
  ) {
    final bool isPlayingFromThisReciter = _isPlayingFromThisReciter(audioState);

    if (isPlayingFromThisReciter) {
      // If playing from this reciter, toggle play/pause
      if (audioState.playbackState?.isPlaying ?? false) {
        context.read<AudioPlayerBloc>().add(
          const AudioPlayerEvent.pauseAudio(),
        );
      } else {
        context.read<AudioPlayerBloc>().add(const AudioPlayerEvent.playAudio());
      }
    } else {
      // If not playing from this reciter, start playing all downloads
      _playAllDownloads(context);
    }
  }

  /// Play all completed downloads for this reciter
  void _playAllDownloads(BuildContext context) {
    context.read<DownloadsBloc>().add(
      DownloadsEvent.playAllDownloads(reciterName: widget.reciterName),
    );
  }
}
