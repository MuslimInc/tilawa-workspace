import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'onboarding_home_preview.dart';

/// Visual treatment for onboarding hero assets.
enum OnboardingHeroStyle {
  /// Flat illustration — no chrome.
  illustration,

  /// Lottie animation — play once, static under reduced motion.
  lottie,

  /// Live Home miniature in a device-style frame.
  devicePreview,

  /// Memorial portrait on a dark mat with a soft hairline frame.
  portrait,
}

/// Hero image for an onboarding slide with a consistent frame per [style].
class OnboardingHeroVisual extends StatelessWidget {
  const OnboardingHeroVisual({
    super.key,
    required this.assetPath,
    required this.style,
  });

  final String assetPath;
  final OnboardingHeroStyle style;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;

    return switch (style) {
      OnboardingHeroStyle.illustration => ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: tokens.contentMaxWidthForm * 0.78,
          maxHeight: tokens.iconSizeExtraLarge * 4.5,
        ),
        child: Image.asset(assetPath, fit: BoxFit.contain),
      ),
      OnboardingHeroStyle.lottie => ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: tokens.contentMaxWidthForm * 0.78,
          maxHeight: tokens.iconSizeExtraLarge * 4.5,
        ),
        child: _OnboardingLottieHero(assetPath: assetPath),
      ),
      OnboardingHeroStyle.devicePreview => ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: tokens.contentMaxWidthForm * 0.52,
          maxHeight: tokens.iconSizeExtraLarge * 6.5,
        ),
        child: const _OnboardingPhoneFrame(
          child: OnboardingHomePreview(),
        ),
      ),
      OnboardingHeroStyle.portrait => _OnboardingMemorialPortrait(
        assetPath: assetPath,
        maxWidth: tokens.contentMaxWidthForm * 0.36,
      ),
    };
  }
}

/// Responsive Lottie hero — plays once; first frame under reduced motion.
class _OnboardingLottieHero extends StatelessWidget {
  const _OnboardingLottieHero({required this.assetPath});

  final String assetPath;

  /// Intrinsic size of `muslim_man_praying_mosque.json` (736×876).
  static const double _aspectRatio = 736 / 876;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: Lottie.asset(
        assetPath,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        repeat: false,
        animate: !reduceMotion,
      ),
    );
  }
}

/// Reverent frame for the Abu Hudhayfah dedication portrait.
class _OnboardingMemorialPortrait extends StatelessWidget {
  const _OnboardingMemorialPortrait({
    required this.assetPath,
    required this.maxWidth,
  });

  final String assetPath;
  final double maxWidth;

  /// Source asset dimensions (`ahmed.png`).
  static const double _aspectRatio = 341 / 515;

  /// Crops past the export padding so the face reads clearly.
  static const double _imageScale = 1.06;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme scheme = theme.colorScheme;

    final Color matTop = scheme.surfaceContainerHighest;
    final Color matBottom = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: tokens.opacityEmphasis * 0.55),
      scheme.surfaceContainerHighest,
    );
    final BorderRadius borderRadius = BorderRadius.circular(
      tokens.radiusExtraLarge,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: AspectRatio(
        aspectRatio: _aspectRatio,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: scheme.outlineVariant.withValues(
                alpha: tokens.opacitySubtle * 0.85,
              ),
              width: tokens.borderWidthThin,
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[matTop, matBottom],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: scheme.shadow.withValues(alpha: tokens.opacitySubtle),
                blurRadius: tokens.spaceMedium,
                offset: tokens.shadowOffsetSmall,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.28),
                      radius: 0.85,
                      colors: <Color>[
                        scheme.onSurface.withValues(alpha: 0.08),
                        scheme.surface.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
                Transform.scale(
                  scale: _imageScale,
                  alignment: const Alignment(0, -0.38),
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.38),
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Slim-bezel phone chrome for the onboarding Home preview.
class _OnboardingPhoneFrame extends StatelessWidget {
  const _OnboardingPhoneFrame({required this.child});

  final Widget child;

  /// Tall phone canvas for the Home miniature (9∶20).
  static const double _screenAspectRatio = 9 / 20;

  /// Outer corner radius as a fraction of frame width (~modern phone body).
  static const double _outerCornerWidthFactor = 0.11;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme scheme = theme.colorScheme;
    final Color bezelColor = scheme.brightness == Brightness.light
        ? scheme.onSurface.withValues(alpha: 0.92)
        : scheme.surfaceContainerHigh;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double frameWidth = constraints.maxWidth;
        final double bezel = tokens.spaceSmall;
        final double outerCorner = frameWidth.isFinite
            ? (frameWidth * _outerCornerWidthFactor).clamp(
                tokens.radiusLarge,
                tokens.radiusExtraLarge + tokens.spaceSmall,
              )
            : tokens.radiusExtraLarge;
        // Concentric corners: inner radius = outer − bezel padding.
        final double innerCorner = (outerCorner - bezel).clamp(
          tokens.radiusSmall,
          outerCorner,
        );
        final BorderRadius outerRadius = BorderRadius.circular(outerCorner);
        final BorderRadius innerRadius = BorderRadius.circular(innerCorner);

        return DecoratedBox(
          decoration: BoxDecoration(
            color: bezelColor,
            borderRadius: outerRadius,
            border: Border.all(
              color: scheme.outlineVariant.withValues(
                alpha: tokens.opacitySubtle,
              ),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: scheme.shadow.withValues(
                  alpha: tokens.opacitySubtle * 1.5,
                ),
                blurRadius: tokens.spaceMedium,
                offset: tokens.shadowOffsetMedium,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(bezel),
            child: AspectRatio(
              aspectRatio: _screenAspectRatio,
              child: ClipRRect(
                borderRadius: innerRadius,
                clipBehavior: Clip.antiAlias,
                child: ColoredBox(
                  color: scheme.surface,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
