import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/entities/audio.dart';
import '../../../../core/extensions.dart';
import '../../../../core/utils/file_size_formatter.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../audio_player/presentation/bloc/audio_player_bloc.dart';
import '../../data/services/download_queue_manager.dart';
import '../../domain/entities/download_item.dart';
import '../bloc/downloads_bloc.dart';
import '../extensions/download_item_extensions.dart';

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
    final ThemeData theme = Theme.of(context);

    final String surahName = download.getLocalizedSurahName(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: _buildStatusIcon(context),
      title: Text(surahName, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (download.status == DownloadStatus.downloading)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: LinearProgressIndicator(
                value: download.progress,
                backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                minHeight: 4,
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
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
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              ),
              if (download.fileSize > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '•',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
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
                      color: theme.textTheme.bodySmall?.color,
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
          // Failed / Stuck -> Retry
          if (download.status == DownloadStatus.failed ||
              _isDownloadStuck(download))
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.orange),
              onPressed: () => _handleRetryDownload(context),
              tooltip: context.l10n.retryDownloadTooltip,
            ),

          // Downloading / Pending -> Cancel
          if (download.status == DownloadStatus.downloading ||
              download.status == DownloadStatus.pending)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.grey),
              onPressed: () => _showDeleteDialog(context),
              tooltip: context.l10n.cancel,
            ),

          // Completed -> Play/Pause
          if (download.status == DownloadStatus.completed)
            BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
              builder: (context, audioState) {
                final bool isCurrentlyPlaying = _isCurrentlyPlaying(audioState);
                return IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: isCurrentlyPlaying
                        ? theme.primaryColor
                        : theme.primaryColor.withValues(alpha: 0.1),
                    foregroundColor: isCurrentlyPlaying
                        ? Colors.white
                        : theme.primaryColor,
                  ),
                  icon: Icon(
                    isCurrentlyPlaying &&
                            (audioState.playbackState?.isPlaying ?? false)
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  onPressed: () => _handlePlayPause(context, audioState),
                  tooltip:
                      isCurrentlyPlaying &&
                          (audioState.playbackState?.isPlaying ?? false)
                      ? context.l10n.pause
                      : context.l10n.play,
                );
              },
            ),

          // Menu for additional actions
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
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.l10n.delete,
                      style: TextStyle(color: theme.colorScheme.error),
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
    final downloading = '${context.l10n.downloading} $progress%';

    if (download.status == DownloadStatus.pending) {
      final int queuePosition = getIt<DownloadQueueManager>().getQueuePosition(
        download.id,
      );
      if (queuePosition > 0) {
        return '${context.l10n.pending} (#$queuePosition)';
      }
      return context.l10n.pending;
    }

    return switch (download.status) {
      DownloadStatus.pending => context.l10n.pending,
      DownloadStatus.downloading => downloading,
      DownloadStatus.completed => context.l10n.completed,
      DownloadStatus.failed => context.l10n.error,
      DownloadStatus.paused => context.l10n.pause,
      DownloadStatus.cancelled => context.l10n.cancelled,
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
    return FileSizeFormatter.formatBytes(bytes);
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteDownload),
        content: Text(
          AppLocalizations.of(
            context,
          )!.deleteDownloadConfirmation(download.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
  }

  /// Check if this download is currently playing
  bool _isCurrentlyPlaying(AudioPlayerState audioState) {
    final AudioEntity? currentAudio = audioState.currentAudio;
    if (currentAudio == null) {
      return false;
    }

    // Check if the current audio entity matches this download
    final fileUri = Uri.file(download.filePath).toString();
    return currentAudio.id == fileUri;
  }

  /// Handle play/pause button press
  void _handlePlayPause(BuildContext context, AudioPlayerState audioState) {
    final bool isCurrentlyPlaying = _isCurrentlyPlaying(audioState);

    if (isCurrentlyPlaying) {
      // If this download is currently playing, toggle play/pause
      if (audioState.playbackState?.isPlaying ?? false) {
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
