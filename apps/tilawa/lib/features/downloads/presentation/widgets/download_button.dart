import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_core/network/network_info.dart';

import '../../data/services/downloads_initialization_service.dart';
import '../../domain/repositories/downloads_repository.dart';
import '../../domain/usecases/usecases.dart';
import '../bloc/download_button/download_button_bloc.dart';

/// Download button with independent state management
///
/// Each button creates its own [DownloadButtonBloc] for optimal performance.
/// No longer coupled to global [DownloadsBloc] state, preventing unnecessary rebuilds.
class DownloadButton extends StatelessWidget {
  const DownloadButton({
    super.key,
    required this.url,
    required this.surahTitle,
    required this.reciterName,
    required this.reciterId,
    this.initialIsDownloaded,
    this.initialIsDownloading,
    this.initialProgress,
  });

  final String url;
  final String surahTitle;
  final String reciterName;
  final int reciterId;
  final bool? initialIsDownloaded;
  final bool? initialIsDownloading;
  final double? initialProgress;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        // Try provider first, fall back to GetIt if provider isn't available
        DownloadsRepository repo;
        try {
          repo = context.read<DownloadsRepository>();
        } catch (e) {
          repo = getIt<DownloadsRepository>();
        }

        final bloc = DownloadButtonBloc(
          url: url,
          reciterName: reciterName,
          reciterId: reciterId,
          checkSurahDownloaded: getIt<CheckSurahDownloadedUseCase>(),
          downloadSurah: getIt<DownloadSurahUseCase>(),
          cancelDownload: CancelDownloadUseCase(repo),
          pauseDownload: PauseDownloadUseCase(repo),
          resumeDownload: ResumeDownloadUseCase(repo),
          observeDownloadProgress: ObserveDownloadProgressUseCase(repo),
          networkInfo: getIt<NetworkInfo>(),
          initialIsDownloaded: initialIsDownloaded,
          initialIsDownloading: initialIsDownloading,
          initialProgress: initialProgress,
        );
        // Explicitly initialize after creation
        bloc.add(const DownloadButtonEvent.initialize());
        return bloc;
      },
      child: BlocConsumer<DownloadButtonBloc, DownloadButtonState>(
        listenWhen: (previous, current) =>
            current.shouldShowNetworkError(previous),
        listener: (context, state) {
          state.whenOrNull(
            networkError: (_) {
              ToastUtils.showToast(msg: context.l10n.networkError);
            },
          );
        },
        buildWhen: (previous, current) =>
            current.hasSignificantProgressChange(previous),
        builder: (context, state) {
          return RepaintBoundary(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: state.when(
                initial: () => const _LoadingDownloadButton(),
                readyToDownload: () => _DefaultDownloadButton(
                  onDownload: () {
                    logger.i(
                      '[DownloadButton] Tapped onDownload for $surahTitle',
                    );
                    context.read<DownloadButtonBloc>().add(
                      DownloadButtonEvent.startDownload(surahTitle: surahTitle),
                    );
                  },
                ),
                pending: () => _PendingDownloadButton(
                  onCancel: () {
                    context.read<DownloadButtonBloc>().add(
                      const DownloadButtonEvent.cancel(),
                    );
                  },
                ),
                downloading: (progress, downloadedBytes, totalBytes) =>
                    _DownloadingProgressButton(
                      progress: progress,
                      onPause: () {
                        context.read<DownloadButtonBloc>().add(
                          const DownloadButtonEvent.requestPause(),
                        );
                      },
                      onCancel: () {
                        context.read<DownloadButtonBloc>().add(
                          const DownloadButtonEvent.cancel(),
                        );
                      },
                    ),
                completed: () => const _CompletedDownloadButton(),
                failed: (errorMessage) => _DefaultDownloadButton(
                  onDownload: () {
                    context.read<DownloadButtonBloc>().add(
                      DownloadButtonEvent.startDownload(surahTitle: surahTitle),
                    );
                  },
                ),
                cancelled: () => _DefaultDownloadButton(
                  onDownload: () {
                    context.read<DownloadButtonBloc>().add(
                      DownloadButtonEvent.startDownload(surahTitle: surahTitle),
                    );
                  },
                ),
                paused: () => _PausedDownloadButton(
                  onResume: () {
                    context.read<DownloadButtonBloc>().add(
                      const DownloadButtonEvent.requestResume(),
                    );
                  },
                  onCancel: () {
                    context.read<DownloadButtonBloc>().add(
                      const DownloadButtonEvent.cancel(),
                    );
                  },
                ),
                networkError: (errorMessage) => _DefaultDownloadButton(
                  onDownload: () {
                    context.read<DownloadButtonBloc>().add(
                      DownloadButtonEvent.startDownload(surahTitle: surahTitle),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Completed download state widget
class _CompletedDownloadButton extends StatelessWidget {
  const _CompletedDownloadButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
          child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
        ),
      ),
    );
  }
}

/// Pending download state widget
class _PendingDownloadButton extends StatelessWidget {
  const _PendingDownloadButton({this.onCancel});

  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: InkWell(
          onTap: onCancel,
          borderRadius: BorderRadius.circular(24),
          child: const _PulsingPendingIcon(),
        ),
      ),
    );
  }
}

/// Loading state while checking download status
class _LoadingDownloadButton extends StatelessWidget {
  const _LoadingDownloadButton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// Downloading progress state widget (simplified - no StreamBuilder!)
class _DownloadingProgressButton extends StatelessWidget {
  const _DownloadingProgressButton({
    required this.progress,
    this.onPause,
    this.onCancel,
  });

  final double progress;
  final VoidCallback? onPause;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle for better visibility
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
            // Circular progress indicator
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                value: progress > 0 ? progress : null,
                strokeWidth: 3,
                backgroundColor: theme.primaryColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            ),
            // Percentage text or icon
            InkWell(
              onTap: onPause,
              borderRadius: BorderRadius.circular(18),
              child: progress > 0
                  ? Text(
                      '${(progress * 100).toInt()}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    )
                  : Icon(
                      Icons.pause_rounded,
                      size: 14,
                      color: theme.primaryColor,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paused download state widget
class _PausedDownloadButton extends StatelessWidget {
  const _PausedDownloadButton({required this.onResume, required this.onCancel});

  final VoidCallback onResume;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            // Play icon (Resume)
            IconButton(
              icon: Icon(
                Icons.play_arrow_rounded,
                size: 20,
                color: theme.primaryColor,
              ),
              onPressed: onResume,
            ),
          ],
        ),
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
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        icon: Icon(Icons.download_rounded, color: theme.primaryColor),
        tooltip: context.l10n.download,
        onPressed: onDownload,
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
    final ThemeData theme = Theme.of(context);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing circle
              Container(
                width: 24 + (_animation.value * 8),
                height: 24 + (_animation.value * 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.primaryColor.withValues(
                      alpha: 1.0 - _animation.value,
                    ),
                    width: 2,
                  ),
                ),
              ),
              // Hourglass icon (static)
              child!,
            ],
          );
        },
        // Pass static child to builder to prevent rebuilding it
        child: Icon(
          Icons.hourglass_empty_rounded,
          size: 20,
          color: theme.primaryColor,
        ),
      ),
    );
  }
}
