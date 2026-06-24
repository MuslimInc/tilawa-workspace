import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/logger.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../bloc/quran_font_loader_bloc.dart';
import '../bloc/quran_reader_bloc.dart';
import '../theme/quran_reader_theme.dart';
import 'quran_reader_screen.dart';

/// Screen that ensures QCF4 fonts are downloaded and registered with the
/// Flutter engine before displaying the actual [QuranReaderScreen].
///
/// States:
///   initial / checking              → blank (dispatches init immediately)
///   downloading                     → [_DownloadView]
///   registering                     → blank (fast, ~200ms)
///   success                         → [QuranReaderScreen] directly, no loading gate
///   error                           → [_ErrorView]
class QuranFontLoaderScreen extends StatefulWidget {
  const QuranFontLoaderScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah,
  });

  final int surahNumber;
  final int? initialAyah;

  @override
  State<QuranFontLoaderScreen> createState() => _QuranFontLoaderScreenState();
}

class _QuranFontLoaderScreenState extends State<QuranFontLoaderScreen> {
  int? _initialPageNumber;
  bool _didDispatchInit = false;
  // Pre-computed before the reader is shown — built synchronously once we
  // have a success state and a valid BuildContext with MediaQuery data.
  PreparedQuranPageWindow? _initialPreparedWindow;
  Widget? _cachedReaderView;

  @override
  void initState() {
    super.initState();
    if (widget.surahNumber > 0) {
      _initialPageNumber = getPageNumber(
        widget.surahNumber,
        widget.initialAyah ?? 1,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialPageNumber == null && widget.surahNumber <= 0) {
      final hint = context.read<QuranReaderBloc>().state.initialPageHint;
      if (hint != null) {
        _initialPageNumber = hint;
      }
    }
    final int? initialPageNumber = _initialPageNumber;
    if (initialPageNumber != null) {
      final Size viewportSize = context.viewportSize;
      final QuranLayoutMetrics metrics = StandardQuranLayoutStrategy()
          .calculateMetrics(
            context,
            BoxConstraints(
              maxWidth: viewportSize.width,
              maxHeight: viewportSize.height,
            ),
            initialPageNumber,
            quranQcfLocator<MushafService>(),
          );
      quranQcfLocator<QuranFontService>().setRenderFontSize(metrics.fontSize);
    }
    _maybeDispatchInit();
  }

  void _maybeDispatchInit() {
    if (_didDispatchInit || _initialPageNumber == null) return;
    _didDispatchInit = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<QuranFontLoaderBloc>().add(
        QuranFontLoaderEvent.initialize(initialPageNumber: _initialPageNumber!),
      );
    });
  }

  /// Builds the initial [PreparedQuranPageWindow] synchronously.
  ///
  /// Called once when the Bloc emits success — at this point fonts are
  /// registered, JSON data is loaded, and the glyph atlas is pre-warmed.
  /// All 15 [TextPainter.layout()] calls complete in <5ms on any device.
  PreparedQuranPageWindow? _buildInitialPreparedWindow(int pageNumber) {
    if (!quranQcfLocator<QuranFontService>().isQuranDataLoaded) return null;
    if (!quranQcfLocator<QuranFontService>().isFontLoaded(pageNumber)) {
      return null;
    }

    final Size viewportSize = context.viewportSize;
    final strategy = StandardQuranLayoutStrategy();

    // Build a ±2 page window. Only pages whose fonts are already loaded are
    // included — visiblePageNumbers and preparedPages are kept in sync so
    // QuranPageView never asks for a page that isn't prepared.
    const int radius = 2;
    final Map<int, PreparedQuranPage> preparedPages = {};
    final Color textColor = QuranReaderTheme.of(context).textColor;
    final BoxConstraints constraints = BoxConstraints(
      maxWidth: viewportSize.width,
      maxHeight: viewportSize.height,
    );

    final int tWindow = DateTime.now().millisecondsSinceEpoch;

    for (int delta = -radius; delta <= radius; delta++) {
      final int p = (pageNumber + delta).clamp(
        1,
        QuranConstants.totalPagesCount,
      );
      if (preparedPages.containsKey(p)) continue;
      if (!quranQcfLocator<QuranFontService>().isFontLoaded(p)) continue;

      final int tPage = DateTime.now().millisecondsSinceEpoch;
      final QuranLayoutMetrics metrics = strategy.calculateMetrics(
        context,
        constraints,
        p,
        quranQcfLocator<MushafService>(),
      );
      preparedPages[p] = quranQcfLocator<QuranPagePreparationService>()
          .preparePage(
            pageNumber: p,
            metrics: metrics,
            viewportWidth: viewportSize.width,
            textColor: textColor,
            mushafService: quranQcfLocator<MushafService>(),
          );
      assert(() {
        final int tPageDone = DateTime.now().millisecondsSinceEpoch;
        final int pageMs = tPageDone - tPage;
        if (pageMs > 8) {
          logger.d(
            '[PERF][WINDOW] ⚠ p$p prepare=${pageMs}ms exceeds 8ms budget',
          );
        } else {
          logger.d('[PERF][WINDOW] p$p prepare=${pageMs}ms');
        }
        return true;
      }());
    }

    if (!preparedPages.containsKey(pageNumber)) {
      assert(() {
        logger.d(
          '[PERF][WINDOW] ✗ center page $pageNumber font not loaded — window aborted',
        );
        return true;
      }());
      return null;
    }

    assert(() {
      final int tWindowDone = DateTime.now().millisecondsSinceEpoch;
      logger.d(
        '[PERF][WINDOW] initial window built | center=p$pageNumber '
        'pages=${preparedPages.keys.toList()} '
        'total=${tWindowDone - tWindow}ms',
      );
      return true;
    }());

    return PreparedQuranPageWindow(
      centerPage: pageNumber,
      radius: radius,
      // visiblePageNumbers = exactly the pages we prepared — no gaps.
      visiblePageNumbers: preparedPages.keys.toSet(),
      preparedPages: preparedPages,
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialPageNumber = _initialPageNumber;

    return MultiBlocListener(
      listeners: [
        BlocListener<QuranReaderBloc, QuranReaderState>(
          listenWhen: (prev, curr) =>
              widget.surahNumber <= 0 &&
              prev.initialPageHint != curr.initialPageHint &&
              curr.initialPageHint != null,
          listener: (context, state) {
            setState(() => _initialPageNumber = state.initialPageHint!);
            _maybeDispatchInit();
          },
        ),
        BlocListener<QuranFontLoaderBloc, QuranFontLoaderState>(
          listenWhen: (_, current) =>
              current.mapOrNull(error: (_) => true) ?? false,
          listener: (context, state) {
            state.mapOrNull(
              error: (s) {
                final String? message = s.failure.localizedMessage(context);
                if (message != null) {
                  TilawaFeedback.showToast(
                    context,
                    message: message,
                    variant: TilawaFeedbackVariant.error,
                  );
                }
              },
            );
          },
        ),
      ],
      child: BlocBuilder<QuranFontLoaderBloc, QuranFontLoaderState>(
        buildWhen: (prev, curr) {
          if (prev.maybeMap(success: (_) => true, orElse: () => false)) {
            return false;
          }
          if (prev.runtimeType != curr.runtimeType) return true;
          return curr.maybeMap(
            downloading: (s) {
              final prevS = prev.maybeMap(
                downloading: (ps) => ps,
                orElse: () => null,
              );
              if (prevS == null) return true;
              return (s.progress - prevS.progress).abs() > 0.01 ||
                  (s.speedKbps - prevS.speedKbps).abs() > 50;
            },
            orElse: () => false,
          );
        },
        builder: (context, state) {
          final downloading = state.mapOrNull(downloading: (s) => s);
          final error = state.mapOrNull(error: (s) => s);
          final isSuccess = state.maybeMap(
            success: (_) => true,
            orElse: () => false,
          );

          assert(() {
            logger.d(
              '[FONT_UI] build state=${state.runtimeType} | isSuccess=$isSuccess',
            );
            return true;
          }());

          if (isSuccess) {
            if (initialPageNumber == null) {
              // No page yet — blank scaffold while page hint arrives.
              return const Scaffold(body: SizedBox.shrink());
            }

            // Build the prepared window once, synchronously. Cached so
            // subsequent builds (e.g. theme changes) reuse the same object.
            final bool isFirstBuild = _initialPreparedWindow == null;
            final int tSuccess = DateTime.now().millisecondsSinceEpoch;
            _initialPreparedWindow ??= _buildInitialPreparedWindow(
              initialPageNumber,
            );

            assert(() {
              if (isFirstBuild) {
                final int tDone = DateTime.now().millisecondsSinceEpoch;
                if (_initialPreparedWindow != null) {
                  logger.d(
                    '[PERF][STARTUP] window ready | p=$initialPageNumber '
                    'preparedCount=${_initialPreparedWindow!.preparedPages.length} '
                    'windowMs=${tDone - tSuccess}ms',
                  );
                } else {
                  logger.d(
                    '[PERF][STARTUP] ✗ window null for p=$initialPageNumber '
                    '— data=${quranQcfLocator<QuranFontService>().isQuranDataLoaded} '
                    'fontLoaded=${quranQcfLocator<QuranFontService>().isFontLoaded(initialPageNumber)}',
                  );
                }
              }
              return true;
            }());

            _cachedReaderView ??= _ReaderView(
              surahNumber: widget.surahNumber,
              initialAyah: widget.initialAyah,
              initialPageNumber: initialPageNumber,
              initialPreparedWindow: _initialPreparedWindow,
            );

            assert(() {
              logger.d(
                '[PERF][STARTUP] showing ReaderView p=$initialPageNumber',
              );
              return true;
            }());
            return _cachedReaderView!;
          }

          if (error != null) {
            return Scaffold(
              body: _FontLoaderSurface(
                child: _ErrorView(
                  message:
                      error.failure.localizedMessage(context) ??
                      context.l10n.unexpectedError,
                  onRetry: () {
                    final page = initialPageNumber;
                    if (page != null) {
                      context.read<QuranFontLoaderBloc>().add(
                        QuranFontLoaderEvent.initialize(
                          initialPageNumber: page,
                        ),
                      );
                    }
                  },
                ),
              ),
            );
          }

          if (downloading != null) {
            return Scaffold(
              body: _FontLoaderSurface(
                child: _DownloadView(
                  progress: downloading.progress,
                  speedKbps: downloading.speedKbps,
                  etaSeconds: downloading.etaSeconds,
                ),
              ),
            );
          }

          // initial / checking / registering — show blank branded scaffold.
          // These states are fast (<500ms). No spinner needed.
          return const Scaffold(body: SizedBox.shrink());
        },
      ),
    );
  }
}

// ─── View: reader screen wrapper ─────────────────────────────────────────────

class _ReaderView extends StatelessWidget {
  const _ReaderView({
    required this.surahNumber,
    this.initialAyah,
    required this.initialPageNumber,
    this.initialPreparedWindow,
  });

  final int surahNumber;
  final int? initialAyah;
  final int initialPageNumber;
  final PreparedQuranPageWindow? initialPreparedWindow;

  @override
  Widget build(BuildContext context) {
    return QuranReaderScreen(
      surahNumber: surahNumber,
      initialAyah: initialAyah,
      initialPageNumber: initialPageNumber,
      initialPreparedWindow: initialPreparedWindow,
    );
  }
}

// ─── Atom: brand icon ────────────────────────────────────────────────────────

class _FontLoaderSurface extends StatelessWidget {
  const _FontLoaderSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: theme.scaffoldBackgroundColor),
        ExcludeSemantics(
          child: CustomPaint(
            painter: _FontLoaderAmbientPainter(
              colorScheme: colorScheme,
              tokens: tokens,
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _FontLoaderAmbientPainter extends CustomPainter {
  const _FontLoaderAmbientPainter({
    required this.colorScheme,
    required this.tokens,
  });

  final ColorScheme colorScheme;
  final TilawaDesignTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    final center = Offset(size.width * 0.5, size.height * 0.35);
    final stroke = Paint()
      ..color = colorScheme.primary.withValues(
        alpha: tokens.opacitySubtle * 0.45,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = tokens.borderWidthThin;

    for (final factor in <double>[0.36, 0.58, 0.8]) {
      canvas.drawCircle(center, shortest * factor, stroke);
    }
  }

  @override
  bool shouldRepaint(_FontLoaderAmbientPainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme ||
        oldDelegate.tokens != tokens;
  }
}

class _BrandIcon extends StatelessWidget {
  const _BrandIcon();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final tokens = theme.tokens;

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: tokens.opacitySubtle),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.menu_book_rounded, size: 44, color: primary),
    );
  }
}

// ─── View: downloading ───────────────────────────────────────────────────────

class _DownloadView extends StatelessWidget {
  const _DownloadView({
    required this.progress,
    required this.speedKbps,
    required this.etaSeconds,
  });

  final double progress;
  final double speedKbps;
  final int etaSeconds;

  bool get _isExtracting => progress > 0.8;

  String _formatSpeed(double kbps) {
    if (kbps >= 1024) {
      return '${(kbps / 1024).toStringAsFixed(1)} MB/s';
    }
    return '${kbps.toStringAsFixed(0)} KB/s';
  }

  String _formatEta(int seconds) {
    if (seconds <= 0) return '';
    if (seconds < 60) return '${seconds}s';
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final primary = theme.colorScheme.primary;

    final int displayPercent = (progress * 100).toInt();
    final String eta = _formatEta(etaSeconds);
    final bool showStats = !_isExtracting && speedKbps > 0;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: const _BrandIcon()),
          SizedBox(height: tokens.spaceExtraLarge),
          Text(
            context.l10n.preparingFonts,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: tokens.spaceSmall),
          Text(
            context.l10n.fontsDownloadDescription,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(
                alpha: tokens.opacityEmphasis,
              ),
            ),
          ),
          SizedBox(height: tokens.spaceExtraLarge * 1.5),
          TilawaGlassPanel(
            padding: EdgeInsets.all(tokens.spaceExtraLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        _isExtracting
                            ? context.l10n.preparingFonts
                            : context.l10n.downloading,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$displayPercent%',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: tokens.spaceMedium),
                ClipRRect(
                  borderRadius: BorderRadius.circular(tokens.radiusSmall),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: tokens.progressHeight * 2,
                    backgroundColor: theme.colorScheme.outline.withValues(
                      alpha: tokens.opacitySubtle,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                  ),
                ),
                if (showStats) ...[
                  SizedBox(height: tokens.spaceMedium),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatChip(
                        icon: Icons.speed_rounded,
                        label: _formatSpeed(speedKbps),
                      ),
                      if (eta.isNotEmpty)
                        _StatChip(icon: Icons.timer_outlined, label: eta),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Atom: stat chip ─────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: tokens.iconSizeSmall,
          color: theme.colorScheme.onSurface.withValues(
            alpha: tokens.opacityEmphasis,
          ),
        ),
        SizedBox(width: tokens.spaceExtraSmall),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(
              alpha: tokens.opacityEmphasis,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── View: error ─────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final Color error = theme.colorScheme.error;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: error.withValues(alpha: tokens.opacitySubtle),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: error,
            ),
          ),
          SizedBox(height: tokens.spaceExtraLarge),
          Text(
            context.l10n.fontsFailedToLoad,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: tokens.spaceSmall),
          TilawaFeedbackStrip(
            icon: Icons.info_outline_rounded,
            message: message,
            backgroundColor: error.withValues(
              alpha: tokens.opacitySubtle,
            ),
            foregroundColor: error,
          ),
          SizedBox(height: tokens.spaceExtraLarge),
          TilawaButton(
            text: context.l10n.retry,
            variant: TilawaButtonVariant.primary,
            leadingIcon: const Icon(Icons.refresh_rounded),
            onPressed: onRetry,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}
