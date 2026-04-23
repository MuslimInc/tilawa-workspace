import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/entities/audio.dart';

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

    return Card(
      elevation: 0,
      shadowColor: Colors.transparent,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
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
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
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
    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Reciter Avatar
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.1),
                child: Text(
                  widget.reciterName.isNotEmpty
                      ? widget.reciterName[0].toUpperCase()
                      : 'R',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.reciterName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${downloads.length} ${context.l10n.surahs}${widget.downloadsByNarrative.length > 1 ? " • ${widget.downloadsByNarrative.length} narratives" : ""}',
                    style: Theme.of(context).textTheme.bodySmall,
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
                        style: IconButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(8),
                        ),
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
                const SizedBox(width: 8),
                // Expand Icon
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                            color: Theme.of(context).colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            context.l10n.deleteAll,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    height: 1,
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.1),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: Text(
                narrativeName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        height: 1,
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                ],
              );
            }),
            // Divider between narrative sections (except after the last one)
            if (entry.key != widget.downloadsByNarrative.keys.last)
              Divider(
                height: 1,
                thickness: 4,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
