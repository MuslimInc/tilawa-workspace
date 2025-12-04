import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../audio_player/presentation/bloc/audio_player_bloc.dart';
import '../../domain/entities/download_item.dart';
import '../bloc/downloads_bloc.dart';
import 'download_item_card.dart';

class ReciterDownloadsSection extends StatelessWidget {
  const ReciterDownloadsSection({
    super.key,
    required this.reciterName,
    required this.downloads,
  });

  final String reciterName;
  final List<DownloadItem> downloads;

  @override
  Widget build(BuildContext context) {
    return BlocListener<DownloadsBloc, DownloadsState>(
      listener: (context, state) {
        if (state is PlaybackInitiated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (state is DownloadsError) {
          _showErrorSnackBar(context, state.message);
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: ExpansionTile(
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            reciterName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            '${downloads.length} ${AppLocalizations.of(context)!.surahs}',
          ),
          leading: CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).primaryColor.withValues(alpha: 0.1),
            child: Text(
              reciterName.isNotEmpty ? reciterName[0].toUpperCase() : 'R',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Play All button (only if there are completed downloads)
              if (_hasCompletedDownloads())
                BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
                  builder: (context, audioState) {
                    final bool isPlayingFromThisReciter =
                        _isPlayingFromThisReciter(audioState);
                    return IconButton(
                      icon: Icon(
                        isPlayingFromThisReciter &&
                                (audioState.playbackState?.playing ?? false)
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      onPressed: () =>
                          _handlePlayAllPlayPause(context, audioState),
                      tooltip:
                          isPlayingFromThisReciter &&
                              (audioState.playbackState?.playing ?? false)
                          ? AppLocalizations.of(context)!.pauseAll
                          : AppLocalizations.of(context)!.playAll,
                    );
                  },
                ),
              // Menu button
              PopupMenuButton<String>(
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
                        const Icon(Icons.delete, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.deleteAll),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            if (downloads.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 20),
                child: Text(
                  '${downloads.length} ${AppLocalizations.of(context)!.surahs}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
            ...downloads.map((download) {
              return DownloadItemCard(
                download: download,
                onDelete: () {
                  context.read<DownloadsBloc>().add(
                    DeleteDownloadEvent(downloadId: download.id),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showDeleteReciterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteAll),
        content: Text(
          AppLocalizations.of(
            context,
          )!.deleteAllDownloadsConfirmation(reciterName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<DownloadsBloc>().add(
                DeleteReciterDownloads(reciterName: reciterName),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.deleteAll),
          ),
        ],
      ),
    );
  }

  /// Check if there are any completed downloads
  bool _hasCompletedDownloads() {
    return downloads.any(
      (download) => download.status == DownloadStatus.completed,
    );
  }

  /// Check if any download from this reciter is currently playing
  bool _isPlayingFromThisReciter(AudioPlayerState audioState) {
    final MediaItem? currentMediaItem = audioState.mediaItem;
    if (currentMediaItem == null) {
      return false;
    }

    // Check if the current media item is from this reciter
    return currentMediaItem.artist == reciterName;
  }

  /// Handle play all/pause all button press
  void _handlePlayAllPlayPause(
    BuildContext context,
    AudioPlayerState audioState,
  ) {
    final bool isPlayingFromThisReciter = _isPlayingFromThisReciter(audioState);

    if (isPlayingFromThisReciter) {
      // If playing from this reciter, toggle play/pause
      if (audioState.playbackState?.playing ?? false) {
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
      DownloadsEvent.playAllDownloads(reciterName: reciterName),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
