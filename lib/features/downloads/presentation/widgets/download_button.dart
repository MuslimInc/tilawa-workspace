import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/toast_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../router/app_router_config.dart';
import '../../../premium/presentation/widgets/premium_upgrade_dialog.dart';
import '../../data/services/download_service.dart';
import '../../domain/entities/download_item.dart';
import '../bloc/downloads_bloc.dart';

class DownloadButton extends StatefulWidget {
  const DownloadButton({
    super.key,
    required this.surahId,
    required this.surahTitle,
    required this.reciterName,
  });

  final String surahId;
  final String surahTitle;
  final String reciterName;

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _downloadSurah(BuildContext context) {
    context.read<DownloadsBloc>().add(
      DownloadSurahEvent(
        surahId: widget.surahId,
        surahTitle: widget.surahTitle,
        reciterName: widget.reciterName,
      ),
    );

    ToastUtils.showToast(msg: 'Downloading ${widget.surahTitle}...');
  }

  void _showPremiumUpgradeDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => PremiumUpgradeDialog(
        title: 'Premium Required',
        message: message,
        onUpgrade: () {
          const PremiumRoute().push(context);
        },
      ),
    );
  }

  DownloadItem? _getDownloadItem(DownloadsState state) {
    final Map<String, List<DownloadItem>>? downloadsByReciter = state.maybeMap(
      loaded: (s) => s.downloadsByReciter,
      downloadStarted: (s) => s.downloadsByReciter,
      premiumRequired: (s) => s.downloadsByReciter,
      playbackInitiated: (s) => s.downloadsByReciter,
      orElse: () => null,
    );

    if (downloadsByReciter != null) {
      final List<DownloadItem> downloads =
          downloadsByReciter[widget.reciterName] ?? [];

      // Construct the expected composite ID: URL_ReciterName
      final expectedId =
          '${widget.surahId}_${widget.reciterName.replaceAll(' ', '_')}';

      try {
        return downloads.firstWhere((download) => download.id == expectedId);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Get the composite download ID
    final downloadId =
        '${widget.surahId}_${widget.reciterName.replaceAll(' ', '_')}';

    return BlocListener<DownloadsBloc, DownloadsState>(
      listener: (context, state) {
        if (state is PremiumRequired) {
          _showPremiumUpgradeDialog(context, state.message);
        }
      },
      child: BlocBuilder<DownloadsBloc, DownloadsState>(
        builder: (context, state) {
          // Check for download item in loaded state
          final DownloadItem? downloadItem = _getDownloadItem(state);
          final DownloadStatus? status = downloadItem?.status;

          // Route to appropriate state widget
          return switch (status) {
            DownloadStatus.completed => _CompletedDownloadButton(
              animationController: _animationController,
              scaleAnimation: _scaleAnimation,
            ),

            DownloadStatus.failed => _FailedDownloadButton(
              onRetry: () => _downloadSurah(context),
            ),

            DownloadStatus.cancelled => _CancelledDownloadButton(
              onRestart: () => _downloadSurah(context),
            ),

            DownloadStatus.pending => const _PendingDownloadButton(),

            DownloadStatus.downloading => _DownloadingProgressButton(
              downloadId: downloadId,
              downloadItem: downloadItem,
            ),

            _ => _DefaultDownloadButton(
              onDownload: () => _downloadSurah(context),
            ),
          };
        },
      ),
    );
  }
}

/// Completed download state widget
class _CompletedDownloadButton extends StatelessWidget {
  const _CompletedDownloadButton({
    required this.animationController,
    required this.scaleAnimation,
  });

  final AnimationController animationController;
  final Animation<double> scaleAnimation;

  @override
  Widget build(BuildContext context) {
    animationController.forward();
    return ScaleTransition(
      scale: scaleAnimation,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

/// Failed download state widget
class _FailedDownloadButton extends StatelessWidget {
  const _FailedDownloadButton({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        icon: const Icon(Icons.refresh_rounded, color: Colors.orange),
        tooltip: 'Retry download',
        onPressed: onRetry,
      ),
    );
  }
}

/// Cancelled download state widget
class _CancelledDownloadButton extends StatelessWidget {
  const _CancelledDownloadButton({required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        icon: Icon(Icons.download_rounded, color: Colors.grey.shade400),
        tooltip: AppLocalizations.of(context)!.download,
        onPressed: onRestart,
      ),
    );
  }
}

/// Pending download state widget
class _PendingDownloadButton extends StatelessWidget {
  const _PendingDownloadButton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 48,
      height: 48,
      child: Center(child: _PulsingPendingIcon()),
    );
  }
}

/// Downloading progress state widget
class _DownloadingProgressButton extends StatelessWidget {
  const _DownloadingProgressButton({
    required this.downloadId,
    required this.downloadItem,
  });

  final String downloadId;
  final DownloadItem? downloadItem;

  @override
  Widget build(BuildContext context) {
    final DownloadsBloc bloc = context.read<DownloadsBloc>();

    return SizedBox(
      width: 48,
      height: 48,
      child: StreamBuilder<DownloadProgress>(
        // Listen to REAL-TIME progress updates via broadcast stream
        stream: bloc.getDownloadProgressStream(downloadId),
        initialData: downloadItem != null
            ? DownloadProgress(
                id: downloadId,
                status: downloadItem!.status,
                progress: downloadItem!.progress,
                downloadedSize: downloadItem!.downloadedSize,
                fileSize: downloadItem!.fileSize,
              )
            : null,
        builder: (context, snapshot) {
          final DownloadProgress? progress = snapshot.data;
          final double progressValue =
              progress?.progress ?? downloadItem?.progress ?? 0.0;

          return Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle for better visibility
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
                // Circular progress indicator
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    value: progressValue > 0 ? progressValue : null,
                    strokeWidth: 3,
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                // Percentage text or icon
                if (progressValue > 0)
                  Text(
                    '${(progressValue * 100).toInt()}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                else
                  // Show indeterminate spinner icon
                  Icon(
                    Icons.downloading_rounded,
                    size: 14,
                    color: Theme.of(context).primaryColor,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Default download button state widget
class _DefaultDownloadButton extends StatelessWidget {
  const _DefaultDownloadButton({required this.onDownload});

  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.8 + (value * 0.2),
              child: IconButton(
                icon: Icon(
                  Icons.download_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                tooltip: AppLocalizations.of(context)!.download,
                onPressed: onDownload,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Widget for the pulsing pending download icon
class _PulsingPendingIcon extends StatefulWidget {
  const _PulsingPendingIcon();

  @override
  State<_PulsingPendingIcon> createState() => _PulsingPendingIconState();
}

class _PulsingPendingIconState extends State<_PulsingPendingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing circle
            Opacity(
              opacity: 1.0 - _animation.value,
              child: Container(
                width: 24 + (_animation.value * 8),
                height: 24 + (_animation.value * 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),
            // Hourglass icon
            Icon(
              Icons.hourglass_empty_rounded,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
          ],
        );
      },
    );
  }
}
