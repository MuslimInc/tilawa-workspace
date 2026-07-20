import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../foundation/design_tokens.dart';
import '../foundation/tilawa_interactive_surface.dart';
import '../foundation/tilawa_text_roles.dart';
import 'tilawa_loading_indicator.dart';

/// Apple Identity palette for the branded Sign in with Apple button.
///
/// Values follow Apple HIG (black / white pill).
abstract final class AppleSignInButtonBrand {
  static const Color blackFill = Color(0xFF000000);
  static const Color blackLabel = Color(0xFFFFFFFF);

  static const Color whiteFill = Color(0xFFFFFFFF);
  static const Color whiteLabel = Color(0xFF000000);

  static const String logoAsset = 'assets/icons/apple_logo.svg';
  static const String logoPackage = 'tilawa_ui_kit';
}

/// Visual theme for [TilawaAppleSignInButton].
enum AppleSignInButtonAppearance {
  /// Black fill, white label (default HIG).
  black,

  /// White fill, black label.
  white,

  /// [Brightness.light] → [black], [Brightness.dark] → [white].
  auto,
}

/// Branded **Sign in with Apple** control.
class TilawaAppleSignInButton extends StatelessWidget {
  /// Creates an Apple-branded sign-in button.
  const TilawaAppleSignInButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.appearance = AppleSignInButtonAppearance.auto,
    this.semanticLabel,
  });

  /// Localized CTA, e.g. "Sign in with Apple".
  final String label;

  final VoidCallback? onPressed;

  final bool isLoading;

  final bool isFullWidth;

  final AppleSignInButtonAppearance appearance;

  final String? semanticLabel;

  bool get _isDisabled => onPressed == null;

  AppleSignInButtonAppearance _resolvedAppearance(BuildContext context) {
    if (appearance != AppleSignInButtonAppearance.auto) {
      return appearance;
    }
    return Theme.of(context).brightness == Brightness.dark
        ? AppleSignInButtonAppearance.white
        : AppleSignInButtonAppearance.black;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final AppleSignInButtonAppearance resolved = _resolvedAppearance(context);

    final Color fill = switch (resolved) {
      AppleSignInButtonAppearance.black => AppleSignInButtonBrand.blackFill,
      AppleSignInButtonAppearance.white => AppleSignInButtonBrand.whiteFill,
      AppleSignInButtonAppearance.auto => AppleSignInButtonBrand.blackFill,
    };
    final Color labelColor = switch (resolved) {
      AppleSignInButtonAppearance.black => AppleSignInButtonBrand.blackLabel,
      AppleSignInButtonAppearance.white => AppleSignInButtonBrand.whiteLabel,
      AppleSignInButtonAppearance.auto => AppleSignInButtonBrand.blackLabel,
    };

    final TextStyle labelStyle =
        tilawaResolveTextRole(
          theme.textTheme,
          TilawaTextRole.labelLarge,
        ).copyWith(
          fontWeight: FontWeight.w500,
          color: labelColor,
        );

    final double height = tokens.minInteractiveDimension;
    final double logoSize = tokens.iconSizeMedium;
    final double horizontalPadding = tokens.spaceLarge;
    final double contentGap = tokens.spaceMedium;
    final double loadingIndicatorSize = tokens.iconSizeSmall;

    final double cornerRadius = tokens.resolveRadius(
      family: TilawaRadiusFamily.pill,
      height: height,
    );
    final BorderRadius borderRadius = BorderRadius.circular(cornerRadius);

    const ShapeBorder shape = StadiumBorder();

    final Widget logoAndLabel = Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        mainAxisAlignment: .center,
        mainAxisSize: .min,
        spacing: contentGap,
        children: <Widget>[
          Center(
            child: _AppleSignInLogo(size: logoSize, color: labelColor),
          ),
          Flexible(
            child: Row(
              spacing: contentGap,
              mainAxisSize: .min,
              children: [
                Flexible(
                  child: Center(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: labelStyle,
                    ),
                  ),
                ),
                if (isLoading)
                  SizedBox(
                    width: loadingIndicatorSize,
                    height: loadingIndicatorSize,
                    child: TilawaLoadingIndicator(
                      color: labelColor,
                      strokeWidth: 2,
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );

    final Widget sizedContent = SizedBox(
      height: height,
      width: isFullWidth ? double.infinity : null,
      child: logoAndLabel,
    );

    final Widget button = _isDisabled
        ? Material(
            color: fill,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: sizedContent,
          )
        : TilawaInteractiveSurface(
            onTap: onPressed,
            enabled: true,
            button: false,
            borderRadius: borderRadius,
            materialColor: fill,
            materialShape: shape,
            child: sizedContent,
          );

    return RepaintBoundary(
      child: Semantics(
        label: isLoading
            ? '${semanticLabel ?? label}, Loading'
            : (semanticLabel ?? label),
        button: true,
        enabled: !_isDisabled,
        child: ExcludeSemantics(child: button),
      ),
    );
  }
}

class _AppleSignInLogo extends StatelessWidget {
  const _AppleSignInLogo({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      AppleSignInButtonBrand.logoAsset,
      package: AppleSignInButtonBrand.logoPackage,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
