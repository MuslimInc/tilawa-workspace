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

const double _kProgressMinHeight = 3.0;
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

    return Dismissible(
      key: ValueKey('download_${download.id}'),
      direction: DismissDirection.endToStart,
      background: _DismissBackground(colorScheme: colorScheme, tokens: tokens),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      child: _DownloadRow(download: download),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteDownload),
        content: Text(context.l10n.deleteDownloadConfirmation(download.title)),
        actions: [
          TilawaButton(
            text: context.l10n.cancel,
            variant: TilawaButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TilawaButton(
            text: context.l10n.delete,
            variant: TilawaButtonVariant.danger,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground({required this.colorScheme, required this.tokens});

  final ColorScheme colorScheme;
  final TilawaDesignTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: AlignmentDirectional.centerEnd,
      padding: EdgeInsetsDirectional.only(end: tokens.spaceLarge),
      color: colorScheme.error,
      child: Icon(
        Icons.delete_outline_rounded,
        color: colorScheme.onError,
      ),
    );
  }
}

class _DownloadRow extends StatelessWidget {
  const _DownloadRow({required this.download});

  final DownloadItem download;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;
    final String surahName = download.getLocalizedSurahName(context);
    final bool isInFlight =
        download.status == DownloadStatus.downloading ||
        download.status == DownloadStatus.pending;
    final bool isCompleted = download.status == DownloadStatus.completed;
    final bool isFailed =
        download.status == DownloadStatus.failed || _isStuck(download);

    return Material(
      color: colorScheme.surface,
      child: InkWell(
        onTap: isCompleted ? () => _playOrPause(context) : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceLarge,
            vertical: tokens.spaceSmall,
          ),
          child: Row(
            children: [
              _StatusIcon(status: download.status, isStuck: _isStuck(download)),
              SizedBox(width: tokens.spaceMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      surahName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isInFlight) ...[
                      SizedBox(height: tokens.spaceExtraSmall),
                      _InFlightProgress(download: download),
                    ] else if (download.fileSize > 0) ...[
                      SizedBox(height: tokens.spaceTiny),
                      Text(
                        FileSizeFormatter.formatBytes(
                          context,
                          download.fileSize,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: tokens.spaceSmall),
              _TrailingAction(
                download: download,
                isCompleted: isCompleted,
                isFailed: isFailed,
                isInFlight: isInFlight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _playOrPause(BuildContext context) {
    final audioState = context.read<AudioPlayerBloc>().state;
    final fileUri = Uri.file(download.filePath).toString();
    final bool isThisPlaying = audioState.currentAudio?.id == fileUri;

    if (isThisPlaying) {
      if (audioState.playbackState?.isPlaying ?? false) {
        context.read<AudioPlayerBloc>().add(
          const AudioPlayerEvent.pauseAudio(),
        );
      } else {
        context.read<AudioPlayerBloc>().add(const AudioPlayerEvent.playAudio());
      }
      return;
    }
    context.read<DownloadsBloc>().add(
      DownloadsEvent.playDownloadedSurah(downloadId: download.id),
    );
  }

  static bool _isStuck(DownloadItem download) {
    if (download.status != DownloadStatus.downloading) return false;
    if (download.progress > 0.0) return false;
    return DateTime.now().difference(download.createdAt).inSeconds >
        _kStuckThresholdSeconds;
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status, required this.isStuck});

  final DownloadStatus status;
  final bool isStuck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;
    final Color color = _color(colorScheme);
    final IconData icon = _icon();

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: tokens.opacitySubtle),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  IconData _icon() {
    if (isStuck) return Icons.error_outline_rounded;
    return switch (status) {
      DownloadStatus.completed => Icons.check_rounded,
      DownloadStatus.downloading => Icons.downloading_rounded,
      DownloadStatus.failed => Icons.error_outline_rounded,
      DownloadStatus.paused => Icons.pause_rounded,
      DownloadStatus.cancelled => Icons.cancel_outlined,
      DownloadStatus.pending => Icons.schedule_rounded,
    };
  }

  Color _color(ColorScheme colorScheme) {
    if (isStuck) return colorScheme.error;
    return switch (status) {
      DownloadStatus.completed => colorScheme.primary,
      DownloadStatus.downloading => colorScheme.primary,
      DownloadStatus.failed => colorScheme.error,
      DownloadStatus.paused => colorScheme.secondary,
      DownloadStatus.cancelled => colorScheme.outline,
      DownloadStatus.pending => colorScheme.outline,
    };
  }
}

class _InFlightProgress extends StatelessWidget {
  const _InFlightProgress({required this.download});

  final DownloadItem download;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;
    final int percent = (download.progress * 100).toInt();
    final String label = download.status == DownloadStatus.pending
        ? _pendingLabel(context)
        : '${context.l10n.downloading} $percent%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
          child: LinearProgressIndicator(
            value: download.status == DownloadStatus.pending
                ? null
                : download.progress,
            backgroundColor: colorScheme.outline.withValues(
              alpha: tokens.opacitySubtle,
            ),
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            minHeight: _kProgressMinHeight,
          ),
        ),
        SizedBox(height: tokens.spaceTiny),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _pendingLabel(BuildContext context) {
    final int queuePosition =
        getIt<IDownloadQueueService>().getQueuePosition(download.id);
    if (queuePosition > 0) {
      return '${context.l10n.pending} (#$queuePosition)';
    }
    return context.l10n.pending;
  }
}

class _TrailingAction extends StatelessWidget {
  const _TrailingAction({
    required this.download,
    required this.isCompleted,
    required this.isFailed,
    required this.isInFlight,
  });

  final DownloadItem download;
  final bool isCompleted;
  final bool isFailed;
  final bool isInFlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isFailed) {
      return IconButton(
        icon: Icon(Icons.refresh_rounded, color: colorScheme.error),
        onPressed: () => context.read<DownloadsBloc>().add(
          DownloadsEvent.retryDownload(downloadId: download.id),
        ),
        tooltip: context.l10n.retryDownloadTooltip,
      );
    }

    if (isInFlight) {
      // No trailing button — swipe to cancel/delete.
      return const SizedBox.shrink();
    }

    if (isCompleted) {
      return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
        buildWhen: (previous, current) =>
            previous.currentAudio != current.currentAudio ||
            previous.isPlaying != current.isPlaying,
        builder: (context, audioState) {
          final bool isThisPlaying = _isCurrentlyPlaying(audioState);
          final bool isPlaying =
              isThisPlaying && (audioState.playbackState?.isPlaying ?? false);

          return IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: isPlaying
                  ? colorScheme.primary
                  : colorScheme.primary.withValues(
                      alpha: theme.tokens.opacitySubtle,
                    ),
              foregroundColor: isPlaying
                  ? colorScheme.onPrimary
                  : colorScheme.primary,
              visualDensity: VisualDensity.compact,
            ),
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
            onPressed: () => _playOrPause(context, audioState),
            tooltip: isPlaying ? context.l10n.pause : context.l10n.play,
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  bool _isCurrentlyPlaying(AudioPlayerState audioState) {
    final AudioEntity? currentAudio = audioState.currentAudio;
    if (currentAudio == null) return false;
    final fileUri = Uri.file(download.filePath).toString();
    return currentAudio.id == fileUri;
  }

  void _playOrPause(BuildContext context, AudioPlayerState audioState) {
    if (_isCurrentlyPlaying(audioState)) {
      if (audioState.playbackState?.isPlaying ?? false) {
        context.read<AudioPlayerBloc>().add(
          const AudioPlayerEvent.pauseAudio(),
        );
      } else {
        context.read<AudioPlayerBloc>().add(const AudioPlayerEvent.playAudio());
      }
      return;
    }
    context.read<DownloadsBloc>().add(
      DownloadsEvent.playDownloadedSurah(downloadId: download.id),
    );
  }
}
