import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../foundation/design_tokens.dart';
import '../foundation/tilawa_interactive_surface.dart';
import './tilawa_loading_indicator.dart';

/// Google Identity palette for the branded sign-in button.
///
/// Values follow the public Sign in with Google branding guidelines
/// (light / dark / neutral themes, pill shape, 1 dp stroke where applicable).
abstract final class GoogleSignInButtonBrand {
  static const Color lightFill = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFF747775);
  static const Color lightLabel = Color(0xFF1F1F1F);

  static const Color darkFill = Color(0xFF131314);
  static const Color darkBorder = Color(0xFF8E918F);
  static const Color darkLabel = Color(0xFFE3E3E3);

  static const Color neutralFill = Color(0xFFF2F2F2);
  static const Color neutralLabel = Color(0xFF1F1F1F);

  static const double logoSize = 20;
  static const double borderWidth = 1;
  static const double horizontalPadding = 12;
  static const double logoTextGap = 12;
  static const double labelFontSize = 14;
  static const double labelLineHeight = 20;

  static const String logoAsset = 'assets/icons/google_g_logo.svg';
  static const String logoPackage = 'tilawa_ui_kit';
}

/// Visual theme for [TilawaGoogleSignInButton].
enum GoogleSignInButtonAppearance {
  /// White fill, `#747775` stroke, `#1F1F1F` label.
  light,

  /// `#131314` fill, `#8E918F` stroke, `#E3E3E3` label.
  dark,

  /// `#F2F2F2` fill, no stroke, `#1F1F1F` label.
  neutral,

  /// [Brightness.light] → [light], [Brightness.dark] → [dark].
  auto,
}

/// Branded **Sign in with Google** control.
///
/// Uses Google's prescribed colors, pill corners via [TilawaRadiusFamily.pill],
/// Roboto Medium 14/20 label, and the standard multicolor G mark. Logo sits on
/// the leading edge; label is optically centered in the button.
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

  bool get _isDisabled => onPressed == null || isLoading;

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
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
    final GoogleSignInButtonAppearance resolved = _resolvedAppearance(context);

    final Color fill = switch (resolved) {
      GoogleSignInButtonAppearance.light => GoogleSignInButtonBrand.lightFill,
      GoogleSignInButtonAppearance.dark => GoogleSignInButtonBrand.darkFill,
      GoogleSignInButtonAppearance.neutral =>
        GoogleSignInButtonBrand.neutralFill,
      GoogleSignInButtonAppearance.auto => GoogleSignInButtonBrand.lightFill,
    };
    final Color? border = switch (resolved) {
      GoogleSignInButtonAppearance.light => GoogleSignInButtonBrand.lightBorder,
      GoogleSignInButtonAppearance.dark => GoogleSignInButtonBrand.darkBorder,
      GoogleSignInButtonAppearance.neutral => null,
      GoogleSignInButtonAppearance.auto => GoogleSignInButtonBrand.lightBorder,
    };
    final Color labelColor = switch (resolved) {
      GoogleSignInButtonAppearance.light => GoogleSignInButtonBrand.lightLabel,
      GoogleSignInButtonAppearance.dark => GoogleSignInButtonBrand.darkLabel,
      GoogleSignInButtonAppearance.neutral =>
        GoogleSignInButtonBrand.neutralLabel,
      GoogleSignInButtonAppearance.auto => GoogleSignInButtonBrand.lightLabel,
    };

    final TextStyle labelStyle = TextStyle(
      fontFamily: 'Roboto',
      fontSize: GoogleSignInButtonBrand.labelFontSize,
      fontWeight: FontWeight.w500,
      height:
          GoogleSignInButtonBrand.labelLineHeight /
          GoogleSignInButtonBrand.labelFontSize,
      color: _isDisabled ? labelColor.withValues(alpha: 0.38) : labelColor,
    );

    final double height = tokens.minInteractiveDimension;

    final double cornerRadius = tokens.resolveRadius(
      family: TilawaRadiusFamily.pill,
      height: height,
    );
    final BorderRadius borderRadius = BorderRadius.circular(cornerRadius);

    final ShapeBorder shape = border == null
        ? StadiumBorder()
        : StadiumBorder(
            side: BorderSide(
              color: _isDisabled ? border.withValues(alpha: 0.38) : border,
              width: GoogleSignInButtonBrand.borderWidth,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          );

    final double logoBand =
        GoogleSignInButtonBrand.horizontalPadding +
        GoogleSignInButtonBrand.logoSize +
        GoogleSignInButtonBrand.logoTextGap;

    final Widget logoAndLabel = Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: logoBand,
            end: logoBand,
          ),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: labelStyle,
          ),
        ),
        PositionedDirectional(
          start: GoogleSignInButtonBrand.horizontalPadding,
          top: 0,
          bottom: 0,
          child: Center(
            child: const _GoogleSignInLogo(),
          ),
        ),
      ],
    );

    final Widget content = Stack(
      alignment: Alignment.center,
      children: <Widget>[
        IgnorePointer(
          ignoring: isLoading,
          child: Opacity(
            opacity: isLoading ? 0 : 1,
            child: logoAndLabel,
          ),
        ),
        if (isLoading)
          SizedBox(
            height: GoogleSignInButtonBrand.logoSize,
            width: GoogleSignInButtonBrand.logoSize,
            child: TilawaLoadingIndicator(
              color: labelColor,
              strokeWidth: 2,
            ),
          ),
      ],
    );

    final Widget surface = Material(
      color: fill,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: height,
        width: isFullWidth ? double.infinity : null,
        child: content,
      ),
    );

    // The whole branded button gets the kit's press-scale, focus ring, and
    // activation haptic (no Material ink ripple). The outer Semantics owns the
    // accessible button role/label, so the surface's own semantics are excluded.
    final Widget button = TilawaInteractiveSurface(
      onTap: _isDisabled ? null : onPressed,
      enabled: !_isDisabled,
      button: false,
      borderRadius: borderRadius,
      child: surface,
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
  const _GoogleSignInLogo();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      GoogleSignInButtonBrand.logoAsset,
      package: GoogleSignInButtonBrand.logoPackage,
      width: GoogleSignInButtonBrand.logoSize,
      height: GoogleSignInButtonBrand.logoSize,
      fit: BoxFit.contain,
    );
  }
}
