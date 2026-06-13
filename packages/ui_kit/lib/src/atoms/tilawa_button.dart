import 'package:flutter/material.dart';

import '../foundation/design_tokens.dart';
import '../foundation/tilawa_interaction_feedback.dart';
import './tilawa_loading_indicator.dart';

// Material 3 state opacities (m3.material.io — interaction states):
// disabled container 12%, disabled content 38%, pressed state layer 10%.
// Hover is kit-calibrated below the M3 8% default for the soft Tilawa look.
const double _disabledContainerOpacity = 0.12;
const double _disabledContentOpacity = 0.38;
const double _pressedOverlayOpacity = 0.1;
const double _hoverOverlayOpacity = 0.04;

/// Variants for [TilawaButton] determining its visual prominence.
enum TilawaButtonVariant {
  /// Most prominent action, uses primary color.
  primary,

  /// Less prominent than primary, uses secondary container colors.
  secondary,

  /// Outlined button for medium emphasis.
  outline,

  /// Low emphasis button for subtle actions.
  ghost,

  /// Prominent action for destructive operations like deletion.
  danger,

  /// Low-weight destructive action — transparent fill, error-tinted label and
  /// outline. Use for settings-style destructive actions (e.g. "Delete
  /// account") where the action should be reachable but must not dominate the
  /// screen. Pair [danger] (solid) only inside an explicit confirmation step.
  dangerOutline,
}

/// Sizes for [TilawaButton] determining its height and padding.
enum TilawaButtonSize {
  /// Smallest height, useful for tight vertical spacing or small cards.
  small,

  /// Standard height for most mobile interactions.
  medium,

  /// Large height for prominent CTA buttons.
  large,
}

/// A highly customizable, design-system-compliant button component.
///
/// Supports multiple variants, sizes, and states (including loading and disabled).
///
/// [TilawaButton] handles its own internal layout, including icons and
/// loading indicators, while ensuring a minimum touch target of 48×48.
///
/// ## Touch-target contract
///
/// All non-shrink-wrapped buttons are forced to ≥ 48×48
/// ([kTilawaMinInteractiveDimension]) regardless of [size] — a `small`
/// (32 dp visual) button still gets a 48 dp hit target via an outer
/// [ConstrainedBox]. [shrinkWrapTapTarget] is the **only** way to drop below
/// 48 dp and is reserved for *inline text-link* actions where 48 dp would
/// break running text (think a "Learn more" link inside a paragraph). It must
/// **not** be combined with an icon-only or control-style button — doing so
/// ships a sub-target tappable control (WCAG 2.5.5 / the kit's own 48 dp law).
/// This is asserted in debug builds.
///
/// Optional [backgroundColor], [foregroundColor], and [borderColor] override
/// the colours implied by [variant] for branded or marketing surfaces.
class TilawaButton extends StatelessWidget {
  /// Creates a [TilawaButton].
  const TilawaButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = TilawaButtonVariant.primary,
    this.size = TilawaButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.semanticLabel,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderRadius,
    this.padding,
    this.textStyle,
    this.shrinkWrapTapTarget = false,
  }) : assert(
         !shrinkWrapTapTarget || (leadingIcon == null && trailingIcon == null),
         'shrinkWrapTapTarget is for inline text-link actions only and must '
         'not be combined with an icon — an icon button below 48dp violates '
         'the kit touch-target contract. Use a full-size button or '
         'TilawaIconActionButton instead.',
       );

  /// The text label to display.
  final String text;

  /// Callback when the button is tapped. If null, the button is disabled.
  final VoidCallback? onPressed;

  /// Visual style variant of the button.
  final TilawaButtonVariant variant;

  /// Size variant determining height and internal padding.
  final TilawaButtonSize size;

  /// Optional icon to display before the text.
  final Widget? leadingIcon;

  /// Optional icon to display after the text.
  final Widget? trailingIcon;

  /// Whether to show a loading indicator instead of text.
  /// When true, the button is non-interactive.
  final bool isLoading;

  /// Whether the button should take up all available horizontal space.
  final bool isFullWidth;

  /// Optional accessibility label. Defaults to [text] if not provided.
  final String? semanticLabel;

  /// When non-null, replaces the background colour from [variant].
  final Color? backgroundColor;

  /// When non-null, replaces the foreground / label colour from [variant].
  final Color? foregroundColor;

  /// When non-null, replaces the outline border colour (outline variant only
  /// unless you also set a transparent [backgroundColor] for a stroked look).
  final Color? borderColor;

  /// Corner radius; defaults to [TilawaRadiusFamily.pill] from theme height.
  final double? borderRadius;

  /// Insets for label and icons; defaults to horizontal padding from [size].
  final EdgeInsetsGeometry? padding;

  /// Merged on top of the built-in label [TextStyle] (font size from [size]).
  final TextStyle? textStyle;

  /// When true, skips the 48×48 minimum and uses a shrink-wrapped tap
  /// target ([MaterialTapTargetSize.shrinkWrap]).
  final bool shrinkWrapTapTarget;

  /// Whether the button is effectively disabled.
  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Resolve colors based on variant
    final (Color variantBg, Color variantFg, Color? variantBorder) = _getColors(
      colorScheme,
    );
    final Color resolvedBg = backgroundColor ?? variantBg;
    final Color resolvedFg = foregroundColor ?? variantFg;
    final Color? resolvedBorder = borderColor ?? variantBorder;

    // Resolve dimensions based on size
    final (height, horizontalPadding, fontSize, iconSize) = _getDimensions();

    final designTokens = theme.extension<TilawaDesignTokens>();
    // Buttons are tappable affordances → the `pill` radius family: a true
    // pill when short, capped at the card radius when tall, so they never
    // out-round adjacent cards (brand-doc §5; see [TilawaRadiusResolverX]).
    // An explicit [borderRadius] still wins for one-off marketing surfaces.
    final double resolvedRadius =
        borderRadius ??
        designTokens?.resolveRadius(
          family: TilawaRadiusFamily.pill,
          height: height,
        ) ??
        height / 2;
    final EdgeInsetsGeometry resolvedPadding =
        padding ?? EdgeInsets.symmetric(horizontal: horizontalPadding);

    final Color overlayBase = resolvedFg;

    final buttonStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(
        Size(
          isFullWidth ? double.infinity : 0,
          shrinkWrapTapTarget ? 0 : height,
        ),
      ),
      padding: WidgetStateProperty.all(resolvedPadding),
      tapTargetSize: shrinkWrapTapTarget
          ? MaterialTapTargetSize.shrinkWrap
          : MaterialTapTargetSize.padded,
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(
            alpha: _disabledContainerOpacity,
          );
        }
        return resolvedBg;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(
            alpha: _disabledContentOpacity,
          );
        }
        return resolvedFg;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return overlayBase.withValues(alpha: _pressedOverlayOpacity);
        }
        if (states.contains(WidgetState.hovered)) {
          return overlayBase.withValues(alpha: _hoverOverlayOpacity);
        }
        return null;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (resolvedBorder == null) return BorderSide.none;
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(
            color: colorScheme.onSurface.withValues(
              alpha: _disabledContainerOpacity,
            ),
          );
        }
        return BorderSide(color: resolvedBorder);
      }),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(resolvedRadius),
        ),
      ),
      elevation: WidgetStateProperty.all(0),
    );

    final Color contentFg = _isDisabled
        ? colorScheme.onSurface.withValues(alpha: _disabledContentOpacity)
        : resolvedFg;

    final content = _ButtonContent(
      text: text,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      foregroundColor: contentFg,
      fontSize: fontSize,
      iconSize: iconSize,
      textStyle: textStyle,
    );

    final TextButton textButton = TextButton(
      onPressed: _isDisabled ? null : onPressed,
      style: buttonStyle,
      child: content,
    );

    final Widget sizedButton = shrinkWrapTapTarget
        ? textButton
        : ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: textButton,
          );

    return Semantics(
      label: isLoading
          ? '${semanticLabel ?? text}, Loading'
          : (semanticLabel ?? text),
      button: true,
      enabled: !_isDisabled,
      child: TilawaPressAnimation(
        enabled: !_isDisabled,
        child: sizedButton,
      ),
    );
  }

  (Color, Color, Color?) _getColors(ColorScheme colors) {
    return switch (variant) {
      TilawaButtonVariant.primary => (colors.primary, colors.onPrimary, null),
      TilawaButtonVariant.secondary => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
        null,
      ),
      TilawaButtonVariant.outline => (
        Colors.transparent,
        colors.primary,
        colors.outline,
      ),
      TilawaButtonVariant.ghost => (Colors.transparent, colors.primary, null),
      TilawaButtonVariant.danger => (colors.error, colors.onError, null),
      TilawaButtonVariant.dangerOutline => (
        Colors.transparent,
        colors.error,
        colors.error,
      ),
    };
  }

  (double, double, double, double) _getDimensions() {
    return switch (size) {
      TilawaButtonSize.small => (32.0, 12.0, 12.0, 16.0),
      TilawaButtonSize.medium => (48.0, 16.0, 14.0, 20.0),
      TilawaButtonSize.large => (56.0, 24.0, 16.0, 24.0),
    };
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.text,
    required this.foregroundColor,
    required this.fontSize,
    required this.iconSize,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.textStyle,
  });

  final String text;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final Color foregroundColor;
  final double fontSize;
  final double iconSize;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: iconSize,
        width: iconSize,
        child: TilawaLoadingIndicator(color: foregroundColor, strokeWidth: 2),
      );
    }

    // Full-width: [Expanded] so the label uses the row width and ellipsizes.
    // Non–full-width: plain label — [Flexible] would expand to the parent's max
    // width and stretch the button in loose layouts (e.g. illustrated states).
    final label = Center(
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: foregroundColor,
        ).merge(textStyle),
      ),
    );

    final double iconGap = Theme.of(context).tokens.spaceSmall;

    return Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null) ...[
          IconTheme(
            data: IconThemeData(size: iconSize, color: foregroundColor),
            child: leadingIcon!,
          ),
          SizedBox(width: iconGap),
        ],
        if (isFullWidth) Expanded(child: label) else label,
        if (trailingIcon != null) ...[
          SizedBox(width: iconGap),
          IconTheme(
            data: IconThemeData(size: iconSize, color: foregroundColor),
            child: trailingIcon!,
          ),
        ],
      ],
    );
  }
}
