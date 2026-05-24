import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa/core/di/injection.dart';
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

@immutable
class _DownloadPalette {
  const _DownloadPalette({
    required this.accent,
    required this.mutedBackground,
    required this.track,
  });

  final Color accent;
  final Color mutedBackground;
  final Color track;

  factory _DownloadPalette.resolve(
    ColorScheme scheme, {
    required bool catalogChrome,
  }) {
    if (catalogChrome) {
      return _DownloadPalette(
        accent: scheme.onSurfaceVariant,
        mutedBackground: scheme.onSurface.withValues(alpha: 0.1),
        track: scheme.surfaceContainerHigh,
      );
    }
    return _DownloadPalette(
      accent: scheme.primary,
      mutedBackground: scheme.primary.withValues(alpha: 0.12),
      track: scheme.primaryContainer,
    );
  }
}

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
    this.catalogChrome = false,
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

  /// Neutral grey/black download chrome (Reciter details surah rows).
  final bool catalogChrome;

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
          final _DownloadPalette palette = _DownloadPalette.resolve(
            Theme.of(context).colorScheme,
            catalogChrome: catalogChrome,
          );
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
                    palette: palette,
                    onDownload: () {
                      context.read<DownloadButtonBloc>().add(
                        DownloadButtonEvent.startDownload(
                          surahTitle: surahTitle,
                        ),
                      );
                    },
                  ),
                  pending: () => _PendingDownloadButton(
                    palette: palette,
                    onCancel: () {
                      context.read<DownloadButtonBloc>().add(
                        const DownloadButtonEvent.cancel(),
                      );
                    },
                  ),
                  downloading: (progress, downloadedBytes, totalBytes) =>
                      _DownloadingProgressButton(
                        palette: palette,
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
                  completed: () => _CompletedDownloadButton(palette: palette),
                  failed: (errorMessage) => _DefaultDownloadButton(
                    palette: palette,
                    onDownload: () {
                      context.read<DownloadButtonBloc>().add(
                        DownloadButtonEvent.startDownload(
                          surahTitle: surahTitle,
                        ),
                      );
                    },
                  ),
                  cancelled: () => _DefaultDownloadButton(
                    palette: palette,
                    onDownload: () {
                      context.read<DownloadButtonBloc>().add(
                        DownloadButtonEvent.startDownload(
                          surahTitle: surahTitle,
                        ),
                      );
                    },
                  ),
                  paused: () => _PausedDownloadButton(
                    palette: palette,
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
                    palette: palette,
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
  const _CompletedDownloadButton({required this.palette});

  final _DownloadPalette palette;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return SizedBox(
      width: context.minInteractiveDimension,
      height: context.minInteractiveDimension,
      child: Center(
        child: Container(
          width: _kCircleSize,
          height: _kCircleSize,
          decoration: BoxDecoration(
            color: palette.mutedBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            color: palette.accent,
            size: tokens.iconSizeLarge,
          ),
        ),
      ),
    );
  }
}

/// Pending download state widget
class _PendingDownloadButton extends StatelessWidget {
  const _PendingDownloadButton({required this.palette, this.onCancel});

  final _DownloadPalette palette;
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
          child: _PulsingPendingIcon(palette: palette),
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
    required this.palette,
    required this.progress,
    this.onPause,
    this.onCancel,
  });

  final _DownloadPalette palette;
  final double progress;
  final VoidCallback? onPause;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return SizedBox(
      width: context.minInteractiveDimension,
      height: context.minInteractiveDimension,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: _kCircleSize,
              height: _kCircleSize,
              decoration: BoxDecoration(
                color: palette.mutedBackground,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(
              width: _kInnerRingSize,
              height: _kInnerRingSize,
              child: TilawaLoadingIndicator(
                centered: false,
                value: progress > 0 ? progress : null,
                strokeWidth: tokens.progressHeight,
                backgroundColor: palette.track.withValues(
                  alpha: tokens.opacityMedium / 2,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
              ),
            ),
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
                            color: palette.accent,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.pause_rounded,
                          size: tokens.iconSizeSmall,
                          color: palette.accent,
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
  const _PausedDownloadButton({
    required this.palette,
    required this.onResume,
    required this.onCancel,
  });

  final _DownloadPalette palette;
  final VoidCallback onResume;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return SizedBox(
      width: context.minInteractiveDimension,
      height: context.minInteractiveDimension,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: _kCircleSize,
              height: _kCircleSize,
              decoration: BoxDecoration(
                color: palette.mutedBackground,
                shape: BoxShape.circle,
                border: Border.all(
                  color: palette.accent.withValues(
                    alpha: tokens.opacityMedium / 1.5,
                  ),
                  width: tokens.borderWidthThin,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.play_arrow_rounded,
                size: tokens.iconSizeMedium,
                color: palette.accent,
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
  const _DefaultDownloadButton({
    required this.palette,
    required this.onDownload,
  });

  final _DownloadPalette palette;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return SizedBox(
      width: context.minInteractiveDimension,
      height: context.minInteractiveDimension,
      child: IconButton(
        icon: Icon(
          Icons.download_rounded,
          color: palette.accent,
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
  const _PulsingPendingIcon({required this.palette});

  final _DownloadPalette palette;

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
    final tokens = Theme.of(context).tokens;
    final Color accent = widget.palette.accent;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
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
                    color: accent.withValues(alpha: 1.0 - _animation.value),
                    width: _kPulseBorderWidth,
                  ),
                ),
              ),
              child!,
            ],
          );
        },
        child: Icon(
          Icons.hourglass_empty_rounded,
          size: tokens.iconSizeMedium,
          color: accent,
        ),
      ),
    );
  }
}
