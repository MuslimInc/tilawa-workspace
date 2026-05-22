import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Visual treatment for onboarding hero assets.
enum OnboardingHeroStyle {
  /// Flat illustration — no chrome.
  illustration,

  /// App screenshot in a device-style frame.
  devicePreview,

  /// Portrait photo with soft frame and shadow.
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
    final TilawaDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;

    final Widget image = Image.asset(assetPath, fit: BoxFit.contain);

    return switch (style) {
      OnboardingHeroStyle.illustration => ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: tokens.contentMaxWidthForm * 0.78,
          maxHeight: tokens.iconSizeExtraLarge * 4.5,
        ),
        child: image,
      ),
      OnboardingHeroStyle.devicePreview => ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: tokens.contentMaxWidthForm * 0.88,
          maxHeight: tokens.iconSizeExtraLarge * 5.5,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(
                alpha: tokens.opacitySubtle,
              ),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colorScheme.shadow.withValues(
                  alpha: tokens.opacitySubtle,
                ),
                blurRadius: tokens.spaceSmall,
                offset: tokens.shadowOffsetSmall,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceMedium),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(tokens.radiusLarge),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radiusLarge),
                child: image,
              ),
            ),
          ),
        ),
      ),
      OnboardingHeroStyle.portrait => ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: tokens.contentMaxWidthForm * 0.55,
          maxHeight: tokens.iconSizeExtraLarge * 4.25,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colorScheme.shadow.withValues(
                  alpha: tokens.opacitySubtle * 1.5,
                ),
                blurRadius: tokens.spaceMedium,
                offset: tokens.shadowOffsetMedium,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
            child: image,
          ),
        ),
      ),
    };
  }
}
