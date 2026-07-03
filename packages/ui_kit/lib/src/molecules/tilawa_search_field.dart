import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/tilawa_field_shell.dart';
import '../foundation/tilawa_icons.dart';
import '../foundation/design_tokens.dart';
import '../foundation/tilawa_input_style.dart';

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
    this.prefixIcon = TilawaIcons.search,
    this.clearIcon = TilawaIcons.dismiss,
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
    final componentTokens = theme.componentTokens.searchField;
    final colorScheme = theme.colorScheme;
    final bool isCatalog = variant == TilawaSearchFieldVariant.catalog;
    final double fieldHeight = height ?? componentTokens.height;
    final inputStyle = context.inputStyle(
      role: TilawaInputRole.search,
      fieldHeight: fieldHeight,
    );
    final effectiveFillColor =
        backgroundColor ??
        (isCatalog ? colorScheme.surface : componentTokens.backgroundColor);
    final effectiveBorderRadius =
        borderRadius ??
        BorderRadius.circular(
          isCatalog
              ? inputStyle.borderRadius(height: fieldHeight)
              : theme.tokens.resolveRadius(family: TilawaRadiusFamily.chrome),
        );
    final bool hasError = errorText != null && errorText!.trim().isNotEmpty;
    final double? resolvedShellHeight = hasError ? null : fieldHeight;

    return TilawaFieldShell.search(
      style: inputStyle,
      isFocused: isFocused,
      hasError: hasError,
      backgroundColor: effectiveFillColor,
      showShadow: showShadow,
      borderRadiusOverride: effectiveBorderRadius,
      useCatalogBorderColors: isCatalog,
      margin: margin,
      shellHeight: resolvedShellHeight,
      shellConstraints: hasError
          ? BoxConstraints(minHeight: componentTokens.height)
          : null,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onTapOutside: onTapOutside,
        textInputAction: textInputAction,
        scrollPadding: scrollPadding ?? inputStyle.searchScrollPadding,
        textAlignVertical: .center,
        style:
            textStyle ?? inputStyle.searchTextStyle(isCatalogWeight: isCatalog),
        decoration: inputStyle.borderlessDecoration(
          hintText: hintText,
          errorText: hasError ? errorText : null,
          errorStyle: errorStyle ?? inputStyle.searchErrorStyle(),
          hintStyle:
              hintStyle ??
              (isCatalog
                  ? inputStyle.searchHintStyle(isCatalogWeight: true)
                  : theme.textTheme.bodyMedium?.copyWith(
                      color: componentTokens.hintTextColor,
                      fontWeight: FontWeight.w600,
                    )),
          contentPadding: contentPadding ?? inputStyle.searchContentPadding,
          prefixIcon: Icon(
            prefixIcon,
            size: componentTokens.iconSize,
            color: isCatalog
                ? inputStyle.searchPrefixIconColor(isFocused: isFocused)
                : (isFocused
                      ? componentTokens.prefixIconFocusedColor
                      : componentTokens.prefixIconMutedColor),
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

/// Centers [child] within [MeMuslimDesignTokens.contentMaxWidthMedia].
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
    return Align(
      alignment: AlignmentDirectional.topCenter,
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
