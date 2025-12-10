import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../audio_player/presentation/bloc/audio_player_bloc.dart';
import '../../data/services/download_queue_manager.dart';
import '../../domain/entities/download_item.dart';
import '../bloc/downloads_bloc.dart';

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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: _buildStatusIcon(context),
      title: Text(
        download.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (download.status == DownloadStatus.downloading)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: LinearProgressIndicator(
                value: download.progress,
                backgroundColor: Theme.of(
                  context,
                ).dividerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                minHeight: 4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (download.status != DownloadStatus.downloading) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  _getStatusText(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              ),
              if (download.fileSize > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '•',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_formatFileSize(download.downloadedSize)} / ${_formatFileSize(download.fileSize)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (download.status == DownloadStatus.failed ||
              _isDownloadStuck(download))
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.blue),
              onPressed: () => _handleRetryDownload(context),
              tooltip: AppLocalizations.of(context)!.retryDownloadTooltip,
            ),
          if (download.status == DownloadStatus.completed)
            BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
              builder: (context, audioState) {
                final bool isCurrentlyPlaying = _isCurrentlyPlaying(audioState);
                return IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: isCurrentlyPlaying
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    foregroundColor: isCurrentlyPlaying
                        ? Colors.white
                        : Theme.of(context).primaryColor,
                  ),
                  icon: Icon(
                    isCurrentlyPlaying &&
                            (audioState.playbackState?.playing ?? false)
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  onPressed: () => _handlePlayPause(context, audioState),
                  tooltip:
                      isCurrentlyPlaying &&
                          (audioState.playbackState?.playing ?? false)
                      ? AppLocalizations.of(context)!.pause
                      : AppLocalizations.of(context)!.play,
                );
              },
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.delete,
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
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    switch (download.status) {
      case DownloadStatus.completed:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.green, size: 20),
        );
      case DownloadStatus.downloading:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.download_rounded,
            color: Colors.blue,
            size: 20,
          ),
        );
      case DownloadStatus.failed:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: Colors.red,
            size: 20,
          ),
        );
      case DownloadStatus.paused:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.pause_circle_outline_rounded,
            color: Colors.orange,
            size: 20,
          ),
        );
      case DownloadStatus.cancelled:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cancel_outlined,
            color: Colors.grey,
            size: 20,
          ),
        );
      case DownloadStatus.pending:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.schedule_rounded,
            color: Colors.grey,
            size: 20,
          ),
        );
    }
  }

  String _getStatusText(BuildContext context) {
    final int progress = (download.progress * 100).toInt();
    final downloading =
        '${AppLocalizations.of(context)!.downloading} $progress%';

    if (download.status == DownloadStatus.pending) {
      final int queuePosition = DownloadQueueManager.instance.getQueuePosition(
        download.id,
      );
      if (queuePosition > 0) {
        return '${AppLocalizations.of(context)!.pending} (#$queuePosition)';
      }
      return AppLocalizations.of(context)!.pending;
    }

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
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteDownload),
        content: Text(
          AppLocalizations.of(
            context,
          )!.deleteDownloadConfirmation(download.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  /// Check if this download is currently playing
  bool _isCurrentlyPlaying(AudioPlayerState audioState) {
    final MediaItem? currentMediaItem = audioState.mediaItem;
    if (currentMediaItem == null) {
      return false;
    }

    // Check if the current media item matches this download
    final fileUri = Uri.file(download.filePath).toString();
    return currentMediaItem.id == fileUri;
  }

  /// Handle play/pause button press
  void _handlePlayPause(BuildContext context, AudioPlayerState audioState) {
    final bool isCurrentlyPlaying = _isCurrentlyPlaying(audioState);

    if (isCurrentlyPlaying) {
      // If this download is currently playing, toggle play/pause
      if (audioState.playbackState?.playing ?? false) {
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

  /// Check if download is stuck (at 0% for more than 30 seconds)
  bool _isDownloadStuck(DownloadItem download) {
    if (download.status != DownloadStatus.downloading) {
      return false;
    }
    if (download.progress > 0.0) {
      return false;
    }
    final Duration timeSinceCreated = DateTime.now().difference(
      download.createdAt,
    );
    return timeSinceCreated.inSeconds > 30;
  }
}
