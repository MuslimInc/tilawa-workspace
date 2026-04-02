import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../bloc/quran_font_loader_bloc.dart';
import '../bloc/quran_reader_bloc.dart';
import 'quran_reader_screen.dart';

/// Screen that ensures QCF4 fonts are downloaded and registered with the
/// Flutter engine before displaying the actual [QuranReaderScreen].
///
/// States:
///   initial / checking              → [_LoadingView]
///   downloading                     → [_DownloadView]
///   registering                     → [_LoadingView]
///   success                         → [QuranReaderScreen]
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
    // Resolve page number from bloc hint when surahNumber is not provided.
    if (_initialPageNumber == null && widget.surahNumber <= 0) {
      final hint = context.read<QuranReaderBloc>().state.initialPageHint;
      if (hint != null) {
        _initialPageNumber = hint;
      }
    }
    // Dispatch initialize as soon as we have a page number, but only once.
    // Done in didChangeDependencies to avoid the BlocListener race: in profile
    // mode the bloc may already be in 'initial' before the listener registers.
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

  @override
  Widget build(BuildContext context) {
    final initialPageNumber = _initialPageNumber;

    return MultiBlocListener(
      listeners: [
        // If surahNumber is 0, the initialPageHint may arrive asynchronously
        // after this screen is built. When it does, store it and dispatch init.
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
        // Error handling
        BlocListener<QuranFontLoaderBloc, QuranFontLoaderState>(
          listenWhen: (_, current) =>
              current.mapOrNull(error: (_) => true) ?? false,
          listener: (context, state) {
            state.mapOrNull(
              error: (s) => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(s.message),
                  backgroundColor: AppColors.error,
                ),
              ),
            );
          },
        ),
      ],
      child: BlocBuilder<QuranFontLoaderBloc, QuranFontLoaderState>(
        buildWhen: (prev, curr) {
          // Once success, never rebuild — QuranReaderScreen owns all further state.
          if (prev.maybeMap(success: (_) => true, orElse: () => false)) {
            return false;
          }
          // Always rebuild on state type change.
          if (prev.runtimeType != curr.runtimeType) return true;
          // For downloading or warming, only rebuild if progress changed meaningfully.
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
            warming: (s) {
              final prevS = prev.maybeMap(
                warming: (ps) => ps,
                orElse: () => null,
              );
              if (prevS == null) return true;
              // Rebuild every 10 pages or exactly at the end.
              return (s.current - prevS.current).abs() >= 10 ||
                  s.current == 604;
            },
            orElse: () => false,
          );
        },
        builder: (context, state) {
          final warming = state.mapOrNull(warming: (s) => s);
          final downloading = state.mapOrNull(downloading: (s) => s);
          final error = state.mapOrNull(error: (s) => s);
          final isSuccess = state.mapOrNull(success: (_) => true) ?? false;
          final isRegistering =
              state.mapOrNull(registering: (_) => true) ?? false;

          print(
            '[FONT_UI] build state=${state.runtimeType} | isSuccess=$isSuccess | isRegistering=$isRegistering | warming=$warming',
          );

          if (isSuccess) {
            if (_cachedReaderView != null) {
              print('[FONT_UI] showing cached ReaderView (Success)');
              return _cachedReaderView!;
            }
            // Readers MUST have a page number. If we don't have it yet, wait.
            if (initialPageNumber == null) {
              print(
                '[FONT_UI] showing LoadingView (Success but null initialPageNumber)',
              );
              return const _FontLoaderScaffold(child: _LoadingView());
            }
            _cachedReaderView = _ReaderView(
              surahNumber: widget.surahNumber,
              initialAyah: widget.initialAyah,
              initialPageNumber: initialPageNumber,
            );
            print('[FONT_UI] showing ReaderView (Success)');
            return _cachedReaderView!;
          }

          if (error != null) {
            print('[FONT_UI] showing ErrorView');
            return _FontLoaderScaffold(
              child: _ErrorView(
                message: error.message,
                onRetry: () {
                  final page = initialPageNumber;
                  if (page != null) {
                    context.read<QuranFontLoaderBloc>().add(
                      QuranFontLoaderEvent.initialize(initialPageNumber: page),
                    );
                  }
                },
              ),
            );
          }

          if (warming != null) {
            print(
              '[FONT_UI] showing WarmingView: ${warming.current}/${warming.total}',
            );
            return _FontLoaderScaffold(
              child: _WarmingView(
                current: warming.current,
                total: warming.total,
              ),
            );
          }

          if (downloading != null) {
            print('[FONT_UI] showing DownloadView');
            return _FontLoaderScaffold(
              child: _DownloadView(
                progress: downloading.progress,
                speedKbps: downloading.speedKbps,
                etaSeconds: downloading.etaSeconds,
              ),
            );
          }

          if (isRegistering) {
            print('[FONT_UI] showing LoadingView (Registering)');
            return const _FontLoaderScaffold(child: _LoadingView());
          }

          if (error != null) {
            print('[FONT_UI] showing ErrorView');
            return _FontLoaderScaffold(
              child: _ErrorView(
                message: error.message,
                onRetry: () {
                  final page = initialPageNumber;
                  if (page != null) {
                    context.read<QuranFontLoaderBloc>().add(
                      QuranFontLoaderEvent.initialize(initialPageNumber: page),
                    );
                  }
                },
              ),
            );
          }

          return const _FontLoaderScaffold(child: _LoadingView());
        },
      ),
    );
  }
}

// ─── View: reader screen wrapper ──────────────────────────────────────────────

class _ReaderView extends StatelessWidget {
  const _ReaderView({
    required this.surahNumber,
    this.initialAyah,
    required this.initialPageNumber,
  });

  final int surahNumber;
  final int? initialAyah;
  final int initialPageNumber;

  @override
  Widget build(BuildContext context) {
    return QuranReaderScreen(
      surahNumber: surahNumber,
      initialAyah: initialAyah,
      initialPageNumber: initialPageNumber,
    );
  }
}

// ─── Scaffold shell ──────────────────────────────────────────────────────────

class _FontLoaderScaffold extends StatelessWidget {
  const _FontLoaderScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final tokens = theme.tokens;

    return Scaffold(
      body: Stack(
        children: [
          // Ambient background orbs — purely decorative
          Positioned(
            top: -80,
            right: -80,
            child: TilawaAmbientOrb(
              size: 300,
              color: primary,
              opacity: tokens.opacitySubtle,
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: TilawaAmbientOrb(
              size: 240,
              color: primary,
              opacity: tokens.opacitySubtle * 0.6,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceExtraLarge * 1.5,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Atom: brand icon ────────────────────────────────────────────────────────

class _BrandIcon extends StatelessWidget {
  const _BrandIcon();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
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

// ─── View: initial / checking / registering ──────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _BrandIcon(),
          SizedBox(height: tokens.spaceExtraLarge),
          Text(
            context.l10n.loadingQuran,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: tokens.spaceExtraLarge),
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: theme.primaryColor,
            ),
          ),
        ],
      ),
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

  // progress 0–0.8 = download, 0.8–1.0 = extraction
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
    final primary = theme.primaryColor;

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
          // Progress bar inside a glass panel
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

// ─── View: warming (Phase 4 Extreme Pre-warm) ────────────────────────────────

class _WarmingView extends StatelessWidget {
  const _WarmingView({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final primary = theme.primaryColor;

    final double progress = (current / total).clamp(0.0, 1.0);
    final int percent = (progress * 100).toInt();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: _BrandIcon()),
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
            'Building high-performance atlas for all 604 pages...',
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
                    Text(
                      'Warming: Page $current / $total',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$percent%',
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
                SizedBox(height: tokens.spaceSmall),
                Text(
                  'This only happens once to ensure jank-free reading.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: tokens.opacitySubtle * 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Atom: stat chip (speed / ETA) ───────────────────────────────────────────

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

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: tokens.opacitySubtle),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: AppColors.error,
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
            backgroundColor: AppColors.error.withValues(
              alpha: tokens.opacitySubtle,
            ),
            foregroundColor: AppColors.error,
          ),
          SizedBox(height: tokens.spaceExtraLarge),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.l10n.retry),
          ),
        ],
      ),
    );
  }
}
