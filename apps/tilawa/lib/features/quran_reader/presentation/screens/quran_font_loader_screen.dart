import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../bloc/quran_font_loader_bloc.dart';
import 'quran_reader_screen.dart';

/// Screen that ensures QCF4 fonts are downloaded and registered with the
/// Flutter engine before displaying the actual [QuranReaderScreen].
///
/// States:
///   initial / checking              → [_LoadingView]
///   downloading                     → [_DownloadView]
///   registering / success           → [QuranReaderScreen] (registering shows a top banner)
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
  // Lazily created and reused so that registering → success does NOT
  // destroy and recreate the reader widget (which would cause a double initState).
  Widget? _readerScreen;

  Widget get _reader {
    _readerScreen ??= QuranReaderScreen(
      surahNumber: widget.surahNumber,
      initialAyah: widget.initialAyah,
    );
    return _readerScreen!;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuranFontLoaderBloc, QuranFontLoaderState>(
      listenWhen: (_, current) => current.mapOrNull(error: (_) => true) ?? false,
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
      builder: (context, state) {
        final downloading = state.mapOrNull(downloading: (s) => s);
        final error = state.mapOrNull(error: (s) => s);
        final isSuccess = state.mapOrNull(success: (_) => true) ?? false;
        final isRegistering =
            state.mapOrNull(registering: (_) => true) ?? false;

        if (isSuccess || isRegistering) {
          // Keep the reader in a stable Stack slot so that registering→success
          // does NOT change the widget's position in the element tree (which
          // would remount it and cause a second initState).
          return Stack(
            children: [
              _reader,
              if (isRegistering) const _RegisteringBanner(),
            ],
          );
        }
        if (downloading != null) {
          return _FontLoaderScaffold(
            child: _DownloadView(
              progress: downloading.progress,
              speedKbps: downloading.speedKbps,
              etaSeconds: downloading.etaSeconds,
            ),
          );
        }
        if (error != null) {
          return _FontLoaderScaffold(child: _ErrorView(message: error.message));
        }
        return const _FontLoaderScaffold(child: _LoadingView());
      },
    );
  }
}

// ─── Banner: registering fonts in background ─────────────────────────────────

class _RegisteringBanner extends StatelessWidget {
  const _RegisteringBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceMedium,
            vertical: tokens.spaceSmall,
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceMedium,
                vertical: tokens.spaceSmall,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primaryColor,
                    ),
                  ),
                  SizedBox(width: tokens.spaceSmall),
                  Text(
                    context.l10n.loadingQuran,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: tokens.opacityEmphasis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
      child: Icon(
        Icons.menu_book_rounded,
        size: 44,
        color: primary,
      ),
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
                    Text(
                      _isExtracting
                          ? context.l10n.preparingFonts
                          : context.l10n.downloading,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w600,
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
                        _StatChip(
                          icon: Icons.timer_outlined,
                          label: eta,
                        ),
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
  const _ErrorView({required this.message});

  final String message;

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
            onPressed: () => context.read<QuranFontLoaderBloc>().add(
              const QuranFontLoaderEvent.initialize(),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.l10n.retry),
          ),
        ],
      ),
    );
  }
}
