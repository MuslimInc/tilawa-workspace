import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/file_size_formatter.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../audio_player/presentation/bloc/audio_player_bloc.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/services/download_queue_service_interface.dart';
import '../bloc/downloads_bloc.dart';
import '../extensions/download_item_extensions.dart';

// Component-local constants that do not map to global tokens.
const double _kStatusDotSize = 6.0;
const double _kProgressMinHeight = 4.0;
const int _kStuckThresholdSeconds = 30;

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;

    final String surahName = download.getLocalizedSurahName(context);

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceSmall,
      ),
      leading: _buildStatusIcon(context),
      title: Text(
        surahName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (download.status == DownloadStatus.downloading)
            Padding(
              padding: EdgeInsets.only(
                top: tokens.spaceSmall,
                bottom: tokens.spaceTiny,
              ),
              child: LinearProgressIndicator(
                value: download.progress,
                backgroundColor: colorScheme.outline.withValues(
                  alpha: tokens.opacitySubtle,
                ),
                borderRadius: BorderRadius.circular(tokens.radiusSmall),
                minHeight: _kProgressMinHeight,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          SizedBox(height: tokens.spaceTiny),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (download.status != DownloadStatus.downloading) ...[
                Container(
                  width: _kStatusDotSize,
                  height: _kStatusDotSize,
                  decoration: BoxDecoration(
                    color: _getStatusColor(colorScheme),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: _kStatusDotSize),
              ],
              Flexible(
                child: Text(
                  _getStatusText(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (download.fileSize > 0) ...[
                SizedBox(width: tokens.spaceSmall),
                Text('•', style: theme.textTheme.bodySmall),
                SizedBox(width: tokens.spaceSmall),
                Expanded(
                  child: Text(
                    '${_formatFileSize(context, download.downloadedSize)} / ${_formatFileSize(context, download.fileSize)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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
              icon: Icon(Icons.refresh_rounded, color: colorScheme.error),
              onPressed: () => _handleRetryDownload(context),
              tooltip: context.l10n.retryDownloadTooltip,
            ),

          // Downloading / Pending -> Cancel
          if (download.status == DownloadStatus.downloading ||
              download.status == DownloadStatus.pending)
            IconButton(
              icon: Icon(Icons.close_rounded, color: colorScheme.outline),
              onPressed: () => _showDeleteDialog(context),
              tooltip: context.l10n.cancel,
            ),

          // Completed -> Play/Pause
          if (download.status == DownloadStatus.completed)
            BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
              buildWhen: (previous, current) =>
                  previous.currentAudio != current.currentAudio ||
                  previous.isPlaying != current.isPlaying,
              builder: (context, audioState) {
                final bool isCurrentlyPlaying = _isCurrentlyPlaying(audioState);
                return IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: isCurrentlyPlaying
                        ? colorScheme.primary
                        : colorScheme.primary.withValues(
                            alpha: tokens.opacitySubtle,
                          ),
                    foregroundColor: isCurrentlyPlaying
                        ? colorScheme.onPrimary
                        : colorScheme.primary,
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
              borderRadius: BorderRadius.circular(tokens.radiusLarge),
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
                      color: colorScheme.error,
                      size: tokens.iconSizeMedium,
                    ),
                    SizedBox(width: tokens.spaceSmall + tokens.spaceTiny),
                    Text(
                      context.l10n.delete,
                      style: TextStyle(color: colorScheme.error),
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
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).tokens;
    final color = _getStatusColor(colorScheme);

    final icon = switch (download.status) {
      DownloadStatus.completed => Icons.check_rounded,
      DownloadStatus.downloading => Icons.download_rounded,
      DownloadStatus.failed => Icons.error_outline_rounded,
      DownloadStatus.paused => Icons.pause_circle_outline_rounded,
      DownloadStatus.cancelled => Icons.cancel_outlined,
      DownloadStatus.pending => Icons.schedule_rounded,
    };

    return Container(
      padding: EdgeInsets.all(tokens.spaceSmall),
      decoration: BoxDecoration(
        color: color.withValues(alpha: tokens.opacitySubtle),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: tokens.opacitySubtle),
          width: tokens.borderWidthThin,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: tokens.opacityShadow * 0.22),
            blurRadius: tokens.blurShadow * 0.5,
            offset: tokens.shadowOffsetSmall,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: tokens.iconSizeMedium),
    );
  }

  String _getStatusText(BuildContext context) {
    final int progress = (download.progress * 100).toInt();
    final downloading = '${context.l10n.downloading} $progress%';

    if (download.status == DownloadStatus.pending) {
      final int queuePosition = getIt<IDownloadQueueService>().getQueuePosition(
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

  Color _getStatusColor(ColorScheme colorScheme) {
    return switch (download.status) {
      DownloadStatus.completed => colorScheme.primary,
      DownloadStatus.downloading => colorScheme.primary,
      DownloadStatus.failed => colorScheme.error,
      DownloadStatus.paused => colorScheme.secondary,
      DownloadStatus.cancelled => colorScheme.outline,
      DownloadStatus.pending => colorScheme.outline,
    };
  }

  String _formatFileSize(BuildContext context, int bytes) {
    return FileSizeFormatter.formatBytes(context, bytes);
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text(context.l10n.deleteDownload),
          content: Text(
            context.l10n.deleteDownloadConfirmation(download.title),
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
              style: TextButton.styleFrom(foregroundColor: colorScheme.error),
              child: Text(context.l10n.delete),
            ),
          ],
        );
      },
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
    return timeSinceCreated.inSeconds > _kStuckThresholdSeconds;
  }
}
