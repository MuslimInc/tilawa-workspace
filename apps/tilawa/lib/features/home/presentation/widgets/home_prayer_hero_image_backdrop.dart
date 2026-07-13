import 'package:flutter/material.dart';
import 'package:tilawa/features/home/domain/constants/home_hero_assets.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Foreground tokens for Prayer Hero copy over the spiritual image or fallback.
@immutable
class HomePrayerHeroForegroundStyle {
  const HomePrayerHeroForegroundStyle({
    required this.ink,
    required this.muted,
    required this.accent,
    required this.chipBackground,
    required this.chipBorder,
    required this.imageVisible,
  });

  final Color ink;
  final Color muted;
  final Color accent;
  final Color chipBackground;
  final Color chipBorder;
  final bool imageVisible;

  factory HomePrayerHeroForegroundStyle.fallback({
    required ColorScheme colorScheme,
    required TilawaHomeScreenTokens screenTokens,
  }) {
    return HomePrayerHeroForegroundStyle(
      ink: colorScheme.onSurface,
      muted: colorScheme.onSurfaceVariant,
      accent: screenTokens.homePrayerHeroAccent,
      chipBackground: screenTokens.homeHeaderChipBackground,
      chipBorder: Color.alphaBlend(
        screenTokens.homePrayerHeroBorder.withValues(alpha: 0.72),
        colorScheme.outlineVariant.withValues(alpha: 0.28),
      ),
      imageVisible: false,
    );
  }

  factory HomePrayerHeroForegroundStyle.image({
    required TilawaHomeScreenTokens screenTokens,
  }) {
    const Color cream = AppColors.homeNextPrayerGradientNightForeground;
    return HomePrayerHeroForegroundStyle(
      ink: cream,
      muted: cream.withValues(alpha: 0.78),
      accent: screenTokens.homePrayerHeroAccent,
      chipBackground: cream.withValues(alpha: 0.14),
      chipBorder: cream.withValues(alpha: 0.24),
      imageVisible: true,
    );
  }
}

/// Desaturated masjid-arch photograph with a controlled green wash for the
/// Prayer Hero card. Falls back to the neutral sheet surface when the asset
/// cannot load.
class HomePrayerHeroImageBackdrop extends StatefulWidget {
  const HomePrayerHeroImageBackdrop({
    super.key,
    required this.builder,
    this.showImage = true,
  });

  final Widget Function(
    BuildContext context,
    HomePrayerHeroForegroundStyle style,
  )
  builder;

  /// When false (skeleton), skips the photo layer and uses the sheet fallback.
  final bool showImage;

  /// Partial monochrome — keeps warmth without stock-photo saturation.
  static const double _desaturateStrength = 0.58;

  static ColorFilter desaturateFilterFor(double strength) {
    final double inv = 1 - strength;
    const double lumR = 0.2126;
    const double lumG = 0.7152;
    const double lumB = 0.0722;
    return ColorFilter.matrix(<double>[
      inv + strength * lumR,
      strength * lumG,
      strength * lumB,
      0,
      0,
      strength * lumR,
      inv + strength * lumG,
      strength * lumB,
      0,
      0,
      strength * lumR,
      strength * lumG,
      inv + strength * lumB,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  static final ColorFilter desaturateFilter = desaturateFilterFor(
    _desaturateStrength,
  );

  @override
  State<HomePrayerHeroImageBackdrop> createState() =>
      _HomePrayerHeroImageBackdropState();
}

class _HomePrayerHeroImageBackdropState
    extends State<HomePrayerHeroImageBackdrop> {
  bool _imageLoaded = false;
  bool _imageFailed = false;

  void _markImageLoaded() {
    if (!mounted || _imageFailed || _imageLoaded) {
      return;
    }
    setState(() => _imageLoaded = true);
  }

  void _handleImageError(Object error, StackTrace? stackTrace) {
    if (!mounted || _imageFailed) {
      return;
    }
    setState(() {
      _imageFailed = true;
      _imageLoaded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TilawaHomeScreenTokens screenTokens =
        theme.componentTokens.homeScreen;
    final bool imageActive = widget.showImage && !_imageFailed && _imageLoaded;
    final HomePrayerHeroForegroundStyle style = imageActive
        ? HomePrayerHeroForegroundStyle.image(screenTokens: screenTokens)
        : HomePrayerHeroForegroundStyle.fallback(
            colorScheme: colorScheme,
            screenTokens: screenTokens,
          );

    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: _HomePrayerHeroSurface(
            showImageLayer: widget.showImage && !_imageFailed,
            imageLoaded: _imageLoaded,
            onImageLoaded: _markImageLoaded,
            onImageError: _handleImageError,
            screenTokens: screenTokens,
            colorScheme: colorScheme,
          ),
        ),
        widget.builder(context, style),
      ],
    );
  }
}

class _HomePrayerHeroSurface extends StatelessWidget {
  const _HomePrayerHeroSurface({
    required this.showImageLayer,
    required this.imageLoaded,
    required this.onImageLoaded,
    required this.onImageError,
    required this.screenTokens,
    required this.colorScheme,
  });

  final bool showImageLayer;
  final bool imageLoaded;
  final VoidCallback onImageLoaded;
  final ImageErrorListener onImageError;
  final TilawaHomeScreenTokens screenTokens;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final TextDirection direction = Directionality.of(context);
    final Alignment focalAlignment = HomeHeroAssets.wallpaperFocalAlignment(
      direction,
    );
    const Color overlayGreen = AppColors.darkDefaultPrimaryContainer;
    final double width = MediaQuery.sizeOf(context).width;
    final int? cacheWidth = width.isFinite && width > 0
        ? () {
            final int computed =
                (width * MediaQuery.devicePixelRatioOf(context)).round();
            return computed > 0 ? computed : null;
          }()
        : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: screenTokens.homeContentSheetSurface,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showImageLayer)
            Opacity(
              opacity: imageLoaded ? 1 : 0,
              child: ColorFiltered(
                colorFilter: HomePrayerHeroImageBackdrop.desaturateFilter,
                child: Image.asset(
                  HomeHeroAssets.wallpaper,
                  fit: BoxFit.cover,
                  alignment: focalAlignment,
                  cacheWidth: cacheWidth,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                        if (frame != null || wasSynchronouslyLoaded) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            onImageLoaded();
                          });
                        }
                        return child;
                      },
                  errorBuilder: (context, error, stackTrace) {
                    onImageError(error, stackTrace);
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          if (imageLoaded) ...[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: overlayGreen.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: <Color>[
                      overlayGreen.withValues(alpha: 0.78),
                      overlayGreen.withValues(alpha: 0.42),
                      overlayGreen.withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                    stops: const <double>[0, 0.34, 0.62, 1],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: AlignmentDirectional.topStart,
                    radius: 0.82,
                    colors: <Color>[
                      AppColors.brandGoldAccent.withValues(alpha: 0.045),
                      Colors.transparent,
                    ],
                    stops: const <double>[0, 0.68],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topCenter,
                    end: AlignmentDirectional.bottomCenter,
                    colors: <Color>[
                      colorScheme.scrim.withValues(alpha: 0.06),
                      Colors.transparent,
                      colorScheme.scrim.withValues(alpha: 0.08),
                    ],
                    stops: const <double>[0, 0.55, 1],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
