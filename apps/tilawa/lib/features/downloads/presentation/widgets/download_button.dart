import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_core/network/network_info.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/usecases/usecases.dart';
import '../bloc/download_button/download_button_bloc.dart';

// --- Download-button-specific layout constants ---
// These are component-local dimensions that do not map to a global token.
const double _kCircleSize = 36.0;
const double _kInnerRingSize = 32.0;
const double _kPulseBorderWidth = 2.0;
const double _kPulseExpansion = 8.0;
const double _kPercentageFontSize = 9.0;
const double _kFullCircleRadius = 1000.0;
const double _kLoadingIndicatorStrokeWidth = 2.0;
const Duration _kPulseAnimationDuration = Duration(milliseconds: 1500);

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
    this.identifier,
  });

  final String url;
  final String surahTitle;
  final String reciterName;
  final int reciterId;
  final bool? initialIsDownloaded;
  final bool? initialIsDownloading;
  final double? initialProgress;

  /// Semantics identifier prefix for this button.
  ///
  /// When set, a single `Semantics` node sits above the `AnimatedSwitcher`.
  /// Its identifier is `"${identifier}_<suffix>"` where suffix is one of:
  /// `ready`, `pending`, `downloading`, `paused`, `complete`.
  /// Keeping it outside the switcher guarantees only one node exists at a
  /// time — no animation-overlap ambiguity for Maestro.
  final String? identifier;

  String? _semanticId(DownloadButtonState state) {
    if (identifier == null) return null;
    return state.when(
      initial: () => null,
      readyToDownload: () => '${identifier}_ready',
      pending: () => '${identifier}_pending',
      downloading: (_, _, _) => '${identifier}_downloading',
      completed: () => '${identifier}_complete',
      failed: (_) => '${identifier}_ready',
      cancelled: () => '${identifier}_ready',
      paused: () => '${identifier}_paused',
      networkError: (_) => '${identifier}_ready',
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(url),
      create: (context) {
        final bloc = DownloadButtonBloc(
          url: url,
          reciterName: reciterName,
          reciterId: reciterId,
          checkSurahDownloaded: getIt<CheckSurahDownloadedUseCase>(),
          downloadSurah: getIt<DownloadSurahUseCase>(),
          cancelDownload: getIt<CancelDownloadUseCase>(),
          pauseDownload: getIt<PauseDownloadUseCase>(),
          resumeDownload: getIt<ResumeDownloadUseCase>(),
          observeDownloadProgress: getIt<ObserveDownloadProgressUseCase>(),
          getDownloadItem: getIt<GetDownloadItemUseCase>(),
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
          // Provide an explicit onTap on the Semantics node so that
          // accessibility services (and Maestro) can invoke the primary action
          // directly, without competing with the parent InkWell.
          VoidCallback? semanticTap;
          if (identifier != null) {
            semanticTap = state.maybeWhen(
              readyToDownload: () =>
                  () => context.read<DownloadButtonBloc>().add(
                    DownloadButtonEvent.startDownload(surahTitle: surahTitle),
                  ),
              failed: (_) =>
                  () => context.read<DownloadButtonBloc>().add(
                    DownloadButtonEvent.startDownload(surahTitle: surahTitle),
                  ),
              cancelled: () =>
                  () => context.read<DownloadButtonBloc>().add(
                    DownloadButtonEvent.startDownload(surahTitle: surahTitle),
                  ),
              networkError: (_) =>
                  () => context.read<DownloadButtonBloc>().add(
                    DownloadButtonEvent.startDownload(surahTitle: surahTitle),
                  ),
              pending: () =>
                  () => context.read<DownloadButtonBloc>().add(
                    const DownloadButtonEvent.cancel(),
                  ),
              downloading: (p, d, t) =>
                  () => context.read<DownloadButtonBloc>().add(
                    const DownloadButtonEvent.cancel(),
                  ),
              paused: () =>
                  () => context.read<DownloadButtonBloc>().add(
                    const DownloadButtonEvent.requestResume(),
                  ),
              orElse: () => null,
            );
          }
          return Semantics(
            identifier: _semanticId(state),
            onTap: semanticTap,
            child: RepaintBoundary(
              child: AnimatedSwitcher(
                duration: Theme.of(context).tokens.durationMedium,
                child: state.when(
                  initial: () => const _LoadingDownloadButton(),
                  readyToDownload: () => _DefaultDownloadButton(
                    onDownload: () {
                      context.read<DownloadButtonBloc>().add(
                        DownloadButtonEvent.startDownload(
                          surahTitle: surahTitle,
                        ),
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
                        DownloadButtonEvent.startDownload(
                          surahTitle: surahTitle,
                        ),
                      );
                    },
                  ),
                  cancelled: () => _DefaultDownloadButton(
                    onDownload: () {
                      context.read<DownloadButtonBloc>().add(
                        DownloadButtonEvent.startDownload(
                          surahTitle: surahTitle,
                        ),
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
                        DownloadButtonEvent.startDownload(
                          surahTitle: surahTitle,
                        ),
                      );
                    },
                  ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;

    return SizedBox(
      width: context.minInteractiveDimension,
      height: context.minInteractiveDimension,
      child: Center(
        child: Container(
          width: _kCircleSize,
          height: _kCircleSize,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: tokens.opacitySubtle),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            color: colorScheme.primary,
            size: tokens.iconSizeLarge,
          ),
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
    final tokens = Theme.of(context).tokens;

    return SizedBox(
      width: context.minInteractiveDimension,
      height: context.minInteractiveDimension,
      child: Center(
        child: InkWell(
          onTap: onCancel,
          borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
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
    return SizedBox(
      width: context.minInteractiveDimension,
      height: context.minInteractiveDimension,
      child: const TilawaLoadingIndicator(
        strokeWidth: _kLoadingIndicatorStrokeWidth,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;

    return SizedBox(
      width: context.minInteractiveDimension,
      height: context.minInteractiveDimension,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle for better visibility
            Container(
              width: _kCircleSize,
              height: _kCircleSize,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(
                  alpha: tokens.opacitySubtle,
                ),
                shape: BoxShape.circle,
              ),
            ),
            // Circular progress indicator
            SizedBox(
              width: _kInnerRingSize,
              height: _kInnerRingSize,
              child: TilawaLoadingIndicator(
                centered: false,
                value: progress > 0 ? progress : null,
                strokeWidth: tokens.progressHeight,
                backgroundColor: colorScheme.primary.withValues(
                  alpha: tokens.opacityMedium / 2,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
            // Percentage text or icon
            SizedBox(
              width: _kInnerRingSize,
              height: _kInnerRingSize,
              child: InkWell(
                onTap: onPause,
                borderRadius: BorderRadius.circular(_kFullCircleRadius),
                child: progress > 0
                    ? Center(
                        child: Text(
                          '${(progress * 100).toInt()}',
                          style: TextStyle(
                            fontSize: _kPercentageFontSize,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.pause_rounded,
                          size: tokens.iconSizeSmall,
                          color: colorScheme.primary,
                        ),
                      ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;

    return SizedBox(
      width: context.minInteractiveDimension,
      height: context.minInteractiveDimension,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            Container(
              width: _kCircleSize,
              height: _kCircleSize,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(
                  alpha: tokens.opacitySubtle,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withValues(
                    alpha: tokens.opacityMedium / 1.5,
                  ),
                  width: tokens.borderWidthThin,
                ),
              ),
            ),
            // Play icon (Resume)
            IconButton(
              icon: Icon(
                Icons.play_arrow_rounded,
                size: tokens.iconSizeMedium,
                color: colorScheme.primary,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;

    return SizedBox(
      width: context.minInteractiveDimension,
      height: context.minInteractiveDimension,
      child: IconButton(
        icon: Icon(
          Icons.download_rounded,
          color: colorScheme.primary,
          size: tokens.iconSizeLarge,
        ),
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
      duration: _kPulseAnimationDuration,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing circle
              Container(
                width:
                    (tokens.iconSizeLarge) +
                    (_animation.value * _kPulseExpansion),
                height:
                    (tokens.iconSizeLarge) +
                    (_animation.value * _kPulseExpansion),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withValues(
                      alpha: 1.0 - _animation.value,
                    ),
                    width: _kPulseBorderWidth,
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
          size: tokens.iconSizeMedium,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
