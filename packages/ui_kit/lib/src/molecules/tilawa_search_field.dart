import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final componentTokens = theme.componentTokens.searchField;
    final colorScheme = theme.colorScheme;
    final effectiveFillColor =
        backgroundColor ?? componentTokens.backgroundColor;
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(componentTokens.borderRadius);
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
              : (isFocused
                    ? componentTokens.focusedBorderColor
                    : componentTokens.unfocusedBorderColor),
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
            theme.textTheme.bodyMedium?.copyWith(fontWeight: .w600),
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
                color: componentTokens.hintTextColor,
              ),
          contentPadding: contentPadding ?? componentTokens.contentPadding,
          prefixIcon: Icon(
            prefixIcon,
            size: componentTokens.iconSize,
            color: isFocused
                ? componentTokens.prefixIconFocusedColor
                : componentTokens.prefixIconMutedColor,
          ),
          suffixIcon: hasText && onClear != null
              ? IconButton(
                  icon: Icon(clearIcon, size: componentTokens.iconSize),
                  onPressed: onClear,
                )
              : null,
        ),
      ),
    );
  }
}
