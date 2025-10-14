import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzakri/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';
import 'package:muzakri/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';

class DownloadItemCard extends StatelessWidget {
  const DownloadItemCard({
    super.key,
    required this.download,
    required this.onDelete,
  });

  final DownloadItem download;
  final VoidCallback onDelete;

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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: _buildStatusIcon(),
          title: Text(
            download.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (download.status == DownloadStatus.downloading)
                LinearProgressIndicator(
                  value: download.progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                _getStatusText(context),
                style: TextStyle(color: _getStatusColor(), fontSize: 12),
              ),
              if (download.fileSize > 0)
                Text(
                  '${_formatFileSize(download.downloadedSize)} / ${_formatFileSize(download.fileSize)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Retry button (only for failed downloads)
              if (download.status == DownloadStatus.failed)
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.blue),
                  onPressed: () => _handleRetryDownload(context),
                  tooltip: AppLocalizations.of(context)!.retryDownloadTooltip,
                ),
              // Play/Pause button (only for completed downloads)
              if (download.status == DownloadStatus.completed)
                BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
                  builder: (context, audioState) {
                    final isCurrentlyPlaying = _isCurrentlyPlaying(audioState);
                    return IconButton(
                      icon: Icon(
                        isCurrentlyPlaying &&
                                audioState.playbackState?.playing == true
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      onPressed: () => _handlePlayPause(context, audioState),
                      tooltip:
                          isCurrentlyPlaying &&
                              audioState.playbackState?.playing == true
                          ? 'Pause'
                          : 'Play',
                    );
                  },
                ),
              // Menu button
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteDialog(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (download.status) {
      case DownloadStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case DownloadStatus.downloading:
        return const Icon(Icons.download, color: Colors.blue);
      case DownloadStatus.failed:
        return const Icon(Icons.error, color: Colors.red);
      case DownloadStatus.paused:
        return const Icon(Icons.pause_circle, color: Colors.orange);
      case DownloadStatus.cancelled:
        return const Icon(Icons.cancel, color: Colors.grey);
      case DownloadStatus.pending:
        return const Icon(Icons.schedule, color: Colors.grey);
    }
  }

  String _getStatusText(BuildContext context) {
    final progress = (download.progress * 100).toInt();
    final downloading =
        "${AppLocalizations.of(context)!.downloading} $progress%";
    return switch (download.status) {
      DownloadStatus.pending => AppLocalizations.of(context)!.pending,
      DownloadStatus.downloading => downloading,
      DownloadStatus.completed => AppLocalizations.of(context)!.completed,
      DownloadStatus.failed => AppLocalizations.of(context)!.error,
      DownloadStatus.paused => AppLocalizations.of(context)!.pause,
      DownloadStatus.cancelled => AppLocalizations.of(context)!.cancelled,
    };
  }

  Color _getStatusColor() {
    switch (download.status) {
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.paused:
        return Colors.orange;
      case DownloadStatus.cancelled:
        return Colors.grey;
      case DownloadStatus.pending:
        return Colors.grey;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Download'),
        content: Text('Are you sure you want to delete "${download.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Check if this download is currently playing
  bool _isCurrentlyPlaying(AudioPlayerState audioState) {
    final currentMediaItem = audioState.mediaItem;
    if (currentMediaItem == null) return false;

    // Check if the current media item matches this download
    final fileUri = Uri.file(download.filePath).toString();
    return currentMediaItem.id == fileUri;
  }

  /// Handle play/pause button press
  void _handlePlayPause(BuildContext context, AudioPlayerState audioState) {
    final isCurrentlyPlaying = _isCurrentlyPlaying(audioState);

    if (isCurrentlyPlaying) {
      // If this download is currently playing, toggle play/pause
      if (audioState.playbackState?.playing == true) {
        context.read<AudioPlayerBloc>().add(
          const AudioPlayerEvent.pauseAudio(),
        );
      } else {
        context.read<AudioPlayerBloc>().add(const AudioPlayerEvent.playAudio());
      }
    } else {
      // If this download is not playing, start playing it
      _playDownloadedSurah(context);
    }
  }

  /// Play the downloaded surah
  void _playDownloadedSurah(BuildContext context) {
    context.read<DownloadsBloc>().add(
      DownloadsEvent.playDownloadedSurah(downloadId: download.id),
    );
  }

  /// Handle retry download button press
  void _handleRetryDownload(BuildContext context) {
    context.read<DownloadsBloc>().add(
      DownloadsEvent.retryDownload(downloadId: download.id),
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
