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

  /// Readable copy over [HomeHeroBackground] period gradients (no photograph).
  factory HomePrayerHeroForegroundStyle.fromHeroTokens({
    required TilawaHomeNextPrayerHeroTokens heroTokens,
    required TilawaHomeScreenTokens screenTokens,
  }) {
    final Color ink = heroTokens.foregroundColor;
    return HomePrayerHeroForegroundStyle(
      ink: ink,
      muted: ink.withValues(alpha: heroTokens.mutedForegroundOpacity),
      accent: screenTokens.homePrayerHeroAccent,
      chipBackground: ink.withValues(
        alpha: heroTokens.locationChipFillOpacity,
      ),
      chipBorder: ink.withValues(
        alpha: heroTokens.locationChipBorderOpacity,
      ),
      imageVisible: false,
    );
  }
}

/// Optional desaturated photograph surface for Prayer Hero experiments.
///
/// Production Home next-prayer uses [HomeHeroBackground] period gradients
/// instead — see `home_next_prayer_time.dart`.
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
            onImageLoaded: _markImageLoaded,
            onImageError: _handleImageError,
            screenTokens: screenTokens,
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
    required this.onImageLoaded,
    required this.onImageError,
    required this.screenTokens,
  });

  final bool showImageLayer;
  final VoidCallback onImageLoaded;
  final ImageErrorListener onImageError;
  final TilawaHomeScreenTokens screenTokens;

  @override
  Widget build(BuildContext context) {
    final TextDirection direction = Directionality.of(context);
    final Alignment focalAlignment = HomeHeroAssets.wallpaperFocalAlignment(
      direction,
    );
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
      child: showImageLayer
          ? ColorFiltered(
              colorFilter: HomePrayerHeroImageBackdrop.desaturateFilter,
              child: Image.asset(
                HomeHeroAssets.wallpaper,
                fit: BoxFit.cover,
                alignment: focalAlignment,
                cacheWidth: cacheWidth,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
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
            )
          : null,
    );
  }
}
