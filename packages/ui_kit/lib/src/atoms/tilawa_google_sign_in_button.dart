import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../foundation/design_tokens.dart';
import '../foundation/tilawa_interactive_surface.dart';
import '../foundation/tilawa_text_roles.dart';
import 'tilawa_loading_indicator.dart';

/// Google Identity palette for the branded sign-in button.
///
/// Values follow the public Sign in with Google branding guidelines
/// (light / dark / neutral themes, pill shape).
abstract final class GoogleSignInButtonBrand {
  static const Color lightFill = Color(0xFFFFFFFF);
  static const Color lightLabel = Color(0xFF1F1F1F);

  static const Color darkFill = Color(0xFF131314);
  static const Color darkLabel = Color(0xFFE3E3E3);

  static const Color neutralFill = Color(0xFFF2F2F2);
  static const Color neutralLabel = Color(0xFF1F1F1F);

  static const String logoAsset = 'assets/icons/google_g_logo.svg';
  static const String logoPackage = 'tilawa_ui_kit';
}

/// Visual theme for [TilawaGoogleSignInButton].
enum GoogleSignInButtonAppearance {
  /// White fill, `#1F1F1F` label.
  light,

  /// `#131314` fill, `#E3E3E3` label.
  dark,

  /// `#F2F2F2` fill, no stroke, `#1F1F1F` label.
  neutral,

  /// [Brightness.light] → [light], [Brightness.dark] → [dark].
  auto,
}

/// Branded **Sign in with Google** control.
///
/// Uses Google's prescribed colors, pill corners via [TilawaRadiusFamily.pill],
/// [TilawaTextRole.labelLarge] label typography from the app theme, and the
/// standard multicolor G mark. Logo sits on the leading edge; label is
/// optically centered in the button.
class TilawaGoogleSignInButton extends StatelessWidget {
  /// Creates a Google-branded sign-in button.
  const TilawaGoogleSignInButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.appearance = GoogleSignInButtonAppearance.auto,
    this.semanticLabel,
  });

  /// Localized CTA, e.g. "Sign in with Google".
  final String label;

  final VoidCallback? onPressed;

  final bool isLoading;

  final bool isFullWidth;

  final GoogleSignInButtonAppearance appearance;

  final String? semanticLabel;

  bool get _isDisabled => onPressed == null;

  GoogleSignInButtonAppearance _resolvedAppearance(BuildContext context) {
    if (appearance != GoogleSignInButtonAppearance.auto) {
      return appearance;
    }
    return Theme.of(context).brightness == Brightness.dark
        ? GoogleSignInButtonAppearance.dark
        : GoogleSignInButtonAppearance.light;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final GoogleSignInButtonAppearance resolved = _resolvedAppearance(context);

    final Color fill = switch (resolved) {
      GoogleSignInButtonAppearance.light => GoogleSignInButtonBrand.lightFill,
      GoogleSignInButtonAppearance.dark => GoogleSignInButtonBrand.darkFill,
      GoogleSignInButtonAppearance.neutral =>
        GoogleSignInButtonBrand.neutralFill,
      GoogleSignInButtonAppearance.auto => GoogleSignInButtonBrand.lightFill,
    };
    final Color labelColor = switch (resolved) {
      GoogleSignInButtonAppearance.light => GoogleSignInButtonBrand.lightLabel,
      GoogleSignInButtonAppearance.dark => GoogleSignInButtonBrand.darkLabel,
      GoogleSignInButtonAppearance.neutral =>
        GoogleSignInButtonBrand.neutralLabel,
      GoogleSignInButtonAppearance.auto => GoogleSignInButtonBrand.lightLabel,
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
            child: _GoogleSignInLogo(size: logoSize),
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

    // The whole branded button gets soft ink splash/highlight, state-layer press,
    // focus ring, and activation haptic. The surface owns the Material fill so
    // ink renders on the button face. Outer Semantics owns the accessible button
    // role/label, so the surface's own semantics are excluded.
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

/// Cached multicolor G mark — kept mounted while loading toggles.
class _GoogleSignInLogo extends StatelessWidget {
  const _GoogleSignInLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      GoogleSignInButtonBrand.logoAsset,
      package: GoogleSignInButtonBrand.logoPackage,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
