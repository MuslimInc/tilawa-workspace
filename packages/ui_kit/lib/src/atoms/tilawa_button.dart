import 'package:flutter/material.dart';
import '../foundation/design_tokens.dart';
import './tilawa_loading_indicator.dart';

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
}

/// Sizes for [TilawaButton] determining its height and padding.
enum TilawaButtonSize {
  /// Smallest height, useful for dense UI or small cards.
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
/// loading indicators, while ensuring a minimum touch target of 48x48.
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
  });

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

  /// Whether the button is effectively disabled.
  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Resolve colors based on variant
    final (backgroundColor, foregroundColor, borderColor) = _getColors(
      colorScheme,
    );

    // Resolve dimensions based on size
    final (height, horizontalPadding, fontSize, iconSize) = _getDimensions();

    final designTokens = theme.extension<TilawaDesignTokens>();
    final borderRadius = designTokens?.radiusMedium ?? 12.0;

    final buttonStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(
        Size(isFullWidth ? double.infinity : 0, height),
      ),
      padding: WidgetStateProperty.all(
        EdgeInsets.symmetric(horizontal: horizontalPadding),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(alpha: 0.12);
        }
        return backgroundColor;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(alpha: 0.38);
        }
        return foregroundColor;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return foregroundColor.withValues(alpha: 0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return foregroundColor.withValues(alpha: 0.04);
        }
        return null;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (borderColor == null) return BorderSide.none;
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.12),
          );
        }
        return BorderSide(color: borderColor);
      }),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      elevation: WidgetStateProperty.all(0),
    );

    final content = _ButtonContent(
      text: text,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      foregroundColor: _isDisabled
          ? colorScheme.onSurface.withValues(alpha: 0.38)
          : foregroundColor,
      fontSize: fontSize,
      iconSize: iconSize,
    );

    return Semantics(
      label: isLoading
          ? '${semanticLabel ?? text}, Loading'
          : (semanticLabel ?? text),
      button: true,
      enabled: !_isDisabled,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: TextButton(
          onPressed: _isDisabled ? null : onPressed,
          style: buttonStyle,
          child: content,
        ),
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
    };
  }

  (double, double, double, double) _getDimensions() {
    return switch (size) {
      TilawaButtonSize.small => (32.0, 12.0, 12.0, 16.0),
      TilawaButtonSize.medium => (44.0, 16.0, 14.0, 20.0),
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
  });

  final String text;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final Color foregroundColor;
  final double fontSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: iconSize,
        width: iconSize,
        child: TilawaLoadingIndicator(color: foregroundColor, strokeWidth: 2),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasFiniteWidth = constraints.maxWidth.isFinite;
        final label = Text(
          text,
          overflow: hasFiniteWidth ? TextOverflow.ellipsis : null,
          softWrap: false,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: foregroundColor,
          ),
        );

        return Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[
              IconTheme(
                data: IconThemeData(size: iconSize, color: foregroundColor),
                child: leadingIcon!,
              ),
              const SizedBox(width: 8),
            ],
            if (hasFiniteWidth) Flexible(child: label) else label,
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              IconTheme(
                data: IconThemeData(size: iconSize, color: foregroundColor),
                child: trailingIcon!,
              ),
            ],
          ],
        );
      },
    );
  }
}
