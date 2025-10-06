import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzakri/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';
import 'package:muzakri/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:muzakri/features/downloads/presentation/widgets/download_item_card.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';

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
          title: Text(
            reciterName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text('${downloads.length} surahs'),
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
                    final isPlayingFromThisReciter = _isPlayingFromThisReciter(
                      audioState,
                    );
                    return IconButton(
                      icon: Icon(
                        isPlayingFromThisReciter &&
                                audioState.playbackState?.playing == true
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      onPressed: () =>
                          _handlePlayAllPlayPause(context, audioState),
                      tooltip:
                          isPlayingFromThisReciter &&
                              audioState.playbackState?.playing == true
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
          children: downloads.map((download) {
            return DownloadItemCard(
              download: download,
              onDelete: () {
                context.read<DownloadsBloc>().add(
                  DeleteDownloadEvent(downloadId: download.id),
                );
              },
            );
          }).toList(),
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
          'Are you sure you want to delete all downloads for $reciterName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
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
    final currentMediaItem = audioState.mediaItem;
    if (currentMediaItem == null) return false;

    // Check if the current media item is from this reciter
    return currentMediaItem.artist == reciterName;
  }

  /// Handle play all/pause all button press
  void _handlePlayAllPlayPause(
    BuildContext context,
    AudioPlayerState audioState,
  ) {
    final isPlayingFromThisReciter = _isPlayingFromThisReciter(audioState);

    if (isPlayingFromThisReciter) {
      // If playing from this reciter, toggle play/pause
      if (audioState.playbackState?.playing == true) {
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
