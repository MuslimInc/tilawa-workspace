import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

/// Visual treatment for [TilawaSearchField].
enum TilawaSearchFieldVariant {
  /// Filled field using component tokens (default).
  standard,

  /// Outlined neutral pill (Pinterest catalog search).
  catalog,
}

class TilawaSearchField extends StatelessWidget {
  const TilawaSearchField({
    super.key,
    required this.hintText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.margin,
    this.height,
    this.textInputAction,
    this.scrollPadding,
    this.prefixIcon = Icons.search_rounded,
    this.clearIcon = Icons.clear_rounded,
    this.variant = TilawaSearchFieldVariant.catalog,
    this.backgroundColor,
    this.borderRadius,
    this.showShadow = false,
    this.contentPadding,
    this.hintStyle,
    this.textStyle,
    this.enabled = true,
    this.onTapOutside,
    this.errorText,
    this.errorStyle,
    this.clearButtonTooltip,
  });

  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final EdgeInsetsGeometry? margin;
  final double? height;
  final TextInputAction? textInputAction;
  final EdgeInsets? scrollPadding;
  final IconData prefixIcon;
  final IconData clearIcon;
  final TilawaSearchFieldVariant variant;
  final Color? backgroundColor;
  final BorderRadiusGeometry? borderRadius;
  final bool showShadow;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? hintStyle;
  final TextStyle? textStyle;
  final bool enabled;
  final TapRegionCallback? onTapOutside;

  /// Validation or lookup failure message shown under the field.
  ///
  /// When non-null and non-empty, the shell uses [ColorScheme.error] and the
  /// field grows vertically to fit the message.
  final String? errorText;

  /// Style for [errorText]. Defaults to [TextTheme.bodySmall] in
  /// [ColorScheme.error].
  final TextStyle? errorStyle;

  /// Tooltip and accessibility hint for the clear suffix control.
  final String? clearButtonTooltip;

  @override
  Widget build(BuildContext context) {
    final listenables = <Listenable>[?controller, ?focusNode];

    Widget buildField() {
      return _SearchFieldBody(
        hintText: hintText,
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onClear: onClear,
        margin: margin,
        height: height,
        textInputAction: textInputAction,
        scrollPadding: scrollPadding,
        prefixIcon: prefixIcon,
        clearIcon: clearIcon,
        variant: variant,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        showShadow: showShadow,
        contentPadding: contentPadding,
        hintStyle: hintStyle,
        textStyle: textStyle,
        enabled: enabled,
        onTapOutside: onTapOutside,
        errorText: errorText,
        errorStyle: errorStyle,
        clearButtonTooltip: clearButtonTooltip,
        hasText: controller?.text.isNotEmpty ?? false,
        isFocused: focusNode?.hasFocus ?? false,
      );
    }

    if (listenables.isEmpty) {
      return buildField();
    }

    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) => buildField(),
    );
  }
}

class _SearchFieldBody extends StatelessWidget {
  const _SearchFieldBody({
    required this.hintText,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.margin,
    required this.height,
    required this.textInputAction,
    required this.scrollPadding,
    required this.prefixIcon,
    required this.clearIcon,
    required this.variant,
    required this.backgroundColor,
    required this.borderRadius,
    required this.showShadow,
    required this.contentPadding,
    required this.hintStyle,
    required this.textStyle,
    required this.enabled,
    required this.onTapOutside,
    required this.hasText,
    required this.isFocused,
    this.errorText,
    this.errorStyle,
    this.clearButtonTooltip,
  });

  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final EdgeInsetsGeometry? margin;
  final double? height;
  final TextInputAction? textInputAction;
  final EdgeInsets? scrollPadding;
  final IconData prefixIcon;
  final IconData clearIcon;
  final TilawaSearchFieldVariant variant;
  final Color? backgroundColor;
  final BorderRadiusGeometry? borderRadius;
  final bool showShadow;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? hintStyle;
  final TextStyle? textStyle;
  final bool enabled;
  final TapRegionCallback? onTapOutside;
  final bool hasText;
  final bool isFocused;
  final String? errorText;
  final TextStyle? errorStyle;
  final String? clearButtonTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final componentTokens = theme.componentTokens.searchField;
    final colorScheme = theme.colorScheme;
    final bool isCatalog = variant == TilawaSearchFieldVariant.catalog;
    final effectiveFillColor =
        backgroundColor ??
        (isCatalog ? colorScheme.surface : componentTokens.backgroundColor);
    final effectiveBorderRadius =
        borderRadius ??
        BorderRadius.circular(
          isCatalog
              ? tokens.resolveRadius(family: TilawaRadiusFamily.card)
              : tokens.resolveRadius(family: TilawaRadiusFamily.chrome),
        );
    final Color unfocusedBorder = isCatalog
        ? colorScheme.outlineVariant.withValues(
            alpha: tokens.opacityEmphasis,
          )
        : componentTokens.unfocusedBorderColor;
    final Color focusedBorder = isCatalog
        ? colorScheme.onSurface.withValues(alpha: tokens.opacitySubtle * 3)
        : componentTokens.focusedBorderColor;
    final Color prefixMuted = isCatalog
        ? colorScheme.onSurfaceVariant.withValues(
            alpha: tokens.opacityEmphasis,
          )
        : componentTokens.prefixIconMutedColor;
    final Color prefixFocused = isCatalog
        ? colorScheme.onSurfaceVariant
        : componentTokens.prefixIconFocusedColor;
    final bool hasError = errorText != null && errorText!.trim().isNotEmpty;
    final double? shellHeight = hasError
        ? null
        : (height ?? componentTokens.height);

    return Container(
      height: shellHeight,
      constraints: hasError
          ? BoxConstraints(minHeight: componentTokens.height)
          : null,
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveFillColor,
        borderRadius: effectiveBorderRadius,
        border: Border.all(
          color: hasError
              ? colorScheme.error
              : (isFocused ? focusedBorder : unfocusedBorder),
          width: hasError ? 2 : 1,
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: componentTokens.boxShadowColor,
                  blurRadius: componentTokens.shadowBlur,
                  offset: componentTokens.shadowOffset,
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onTapOutside: onTapOutside,
        textInputAction: textInputAction,
        // fix: Spacing & alignment — tokenized scroll inset from component tokens
        scrollPadding: scrollPadding ?? componentTokens.scrollPadding,
        textAlignVertical: .center,
        style:
            textStyle ??
            theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isCatalog ? FontWeight.w400 : FontWeight.w600,
            ),
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          border: .none,
          hintText: hintText,
          errorText: hasError ? errorText : null,
          errorStyle:
              errorStyle ??
              theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
          errorMaxLines: 3,
          hintStyle:
              hintStyle ??
              theme.textTheme.bodyMedium?.copyWith(
                color: isCatalog
                    ? colorScheme.onSurfaceVariant.withValues(
                        alpha: tokens.opacityEmphasis,
                      )
                    : componentTokens.hintTextColor,
                fontWeight: isCatalog ? FontWeight.w400 : FontWeight.w600,
              ),
          contentPadding: contentPadding ?? componentTokens.contentPadding,
          prefixIcon: Icon(
            prefixIcon,
            size: componentTokens.iconSize,
            color: isFocused ? prefixFocused : prefixMuted,
          ),
          suffixIcon: hasText && onClear != null
              ? IconButton(
                  tooltip: clearButtonTooltip,
                  icon: Icon(clearIcon, size: componentTokens.iconSize),
                  onPressed: onClear,
                )
              : null,
        ),
      ),
    );
  }
}

/// Centers [child] within [TilawaDesignTokens.contentMaxWidthMedia].
///
/// Use for feature-screen search rows (Reciters, History, Playlists, etc.)
/// so the field aligns with list content on tablet/desktop.
class TilawaSearchFieldSlot extends StatelessWidget {
  const TilawaSearchFieldSlot({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: tokens.contentMaxWidthMedia),
        child: Padding(
          padding:
              padding ??
              EdgeInsetsDirectional.symmetric(horizontal: tokens.spaceMedium),
          child: child,
        ),
      ),
    );
  }
}
