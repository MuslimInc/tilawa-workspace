import 'package:flutter/material.dart';

import 'component_tokens.dart';
import 'design_tokens.dart';

/// Semantic role for kit input chrome.
///
/// [form] — chrome radius for text fields, dropdowns, date/read-only selectors.
/// [search] — pill radius for catalog/search surfaces (single border owner).
enum TilawaInputRole {
  form,
  search,
}

/// Single source of truth for Tilawa input decoration, borders, radii, and
/// padding.
///
/// Kit input widgets must source all visual chrome from this class — never
/// from [ThemeData.inputDecorationTheme] alone.
class TilawaInputStyle {
  const TilawaInputStyle({
    required this.tokens,
    required this.colorScheme,
    required this.textTheme,
    required this.role,
    this.fieldHeight,
    this.searchTokens,
  });

  final TilawaDesignTokens tokens;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final TilawaInputRole role;

  /// Height used when resolving pill radius for [TilawaInputRole.search].
  final double? fieldHeight;

  final TilawaSearchFieldTokens? searchTokens;

  /// Resolves the kit input style from [context].
  factory TilawaInputStyle.of(
    BuildContext context, {
    TilawaInputRole role = TilawaInputRole.form,
    double? fieldHeight,
  }) {
    final theme = Theme.of(context);
    return TilawaInputStyle(
      tokens: theme.tokens,
      colorScheme: theme.colorScheme,
      textTheme: theme.textTheme,
      role: role,
      fieldHeight: fieldHeight,
      searchTokens: role == TilawaInputRole.search
          ? theme.componentTokens.searchField
          : null,
    );
  }

  /// Corner radius for this [role].
  double borderRadius({double? height}) {
    return switch (role) {
      TilawaInputRole.form => tokens.resolveRadius(
        family: TilawaRadiusFamily.chrome,
      ),
      TilawaInputRole.search => tokens.resolveRadius(
        family: TilawaRadiusFamily.pill,
        height:
            height ??
            fieldHeight ??
            searchTokens?.height ??
            tokens.minInteractiveDimension,
      ),
    };
  }

  /// Standard content padding for form controls.
  EdgeInsetsGeometry formContentPadding({TextStyle? textStyle}) {
    final TextStyle? style = textStyle ?? textTheme.bodyLarge;
    final double lineHeight = (style?.fontSize ?? 16) * (style?.height ?? 1.5);
    final double verticalPadding =
        ((tokens.minInteractiveDimension - lineHeight) / 2).clamp(
          tokens.spaceSmall,
          tokens.spaceLarge,
        );
    return EdgeInsets.symmetric(
      horizontal: tokens.spaceMedium,
      vertical: verticalPadding,
    );
  }

  /// Decoration for form fields and [InputDecorator] shells (single border owner).
  InputDecoration decoration({
    String? labelText,
    String? hintText,
    String? helperText,
    String? errorText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool enabled = true,
    bool alignLabelWithHint = false,
    EdgeInsetsGeometry? contentPadding,
    TextStyle? textStyle,
  }) {
    final double radius = borderRadius();
    final bool hasError = errorText != null && errorText.trim().isNotEmpty;

    OutlineInputBorder outline(BorderSide side) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: side,
    );

    final BorderSide enabledSide = BorderSide(
      color: enabled
          ? colorScheme.outlineVariant
          : colorScheme.onSurface.withValues(alpha: 0.38),
    );
    final BorderSide focusedSide = BorderSide(
      color: colorScheme.primary,
      width: tokens.focusRingWidth,
    );
    final BorderSide errorSide = BorderSide(
      color: colorScheme.error,
      width: tokens.focusRingWidth,
    );

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      enabled: enabled,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding:
          contentPadding ?? formContentPadding(textStyle: textStyle),
      border: outline(enabledSide),
      enabledBorder: outline(enabledSide),
      focusedBorder: outline(focusedSide),
      disabledBorder: outline(enabledSide),
      errorBorder: outline(errorSide),
      focusedErrorBorder: outline(errorSide),
      errorMaxLines: hasError ? 3 : 1,
    );
  }

  /// Borderless decoration for an editable child inside [TilawaFieldShell.search].
  ///
  /// Every border property is explicitly cleared so [ThemeData] defaults cannot
  /// leak an extra outline.
  InputDecoration borderlessDecoration({
    String? hintText,
    String? errorText,
    TextStyle? hintStyle,
    TextStyle? errorStyle,
    EdgeInsetsGeometry? contentPadding,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool isDense = true,
  }) {
    return InputDecoration(
      isDense: isDense,
      filled: false,
      hintText: hintText,
      errorText: errorText,
      hintStyle: hintStyle,
      errorStyle: errorStyle,
      contentPadding: contentPadding,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      errorMaxLines: 3,
    );
  }

  /// Outer shell decoration for [TilawaInputRole.search] (sole border owner).
  BoxDecoration searchShellDecoration({
    required bool isFocused,
    required bool hasError,
    Color? backgroundColor,
    BorderRadiusGeometry? borderRadiusOverride,
    bool showShadow = false,
    bool useCatalogBorderColors = true,
  }) {
    final TilawaSearchFieldTokens search = searchTokens!;
    final double height = fieldHeight ?? search.height;
    final BorderRadiusGeometry effectiveRadius =
        borderRadiusOverride ??
        BorderRadius.circular(borderRadius(height: height));

    final Color borderColor = hasError
        ? colorScheme.error
        : isFocused
        ? (useCatalogBorderColors
              ? colorScheme.onSurface.withValues(
                  alpha: tokens.opacitySubtle * 3,
                )
              : search.focusedBorderColor)
        : (useCatalogBorderColors
              ? colorScheme.outlineVariant.withValues(
                  alpha: tokens.opacityEmphasis,
                )
              : search.unfocusedBorderColor);

    return BoxDecoration(
      color: backgroundColor ?? colorScheme.surface,
      borderRadius: effectiveRadius,
      border: Border.all(
        color: borderColor,
        width: hasError ? tokens.focusRingWidth : 1,
      ),
      boxShadow: showShadow
          ? [
              BoxShadow(
                color: search.boxShadowColor,
                blurRadius: search.shadowBlur,
                offset: search.shadowOffset,
              ),
            ]
          : null,
    );
  }

  Color searchPrefixIconColor({required bool isFocused}) {
    return isFocused
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurfaceVariant.withValues(
            alpha: tokens.opacityEmphasis,
          );
  }

  TextStyle? searchHintStyle({required bool isCatalogWeight}) {
    return textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurfaceVariant.withValues(
        alpha: tokens.opacityEmphasis,
      ),
      fontWeight: isCatalogWeight ? FontWeight.w400 : FontWeight.w600,
    );
  }

  TextStyle? searchTextStyle({required bool isCatalogWeight}) {
    return textTheme.bodyMedium?.copyWith(
      fontWeight: isCatalogWeight ? FontWeight.w400 : FontWeight.w600,
    );
  }

  TextStyle searchErrorStyle() {
    return textTheme.bodySmall!.copyWith(
      color: colorScheme.error,
      fontWeight: FontWeight.w500,
    );
  }

  EdgeInsetsGeometry get searchContentPadding => searchTokens!.contentPadding;

  EdgeInsets get searchScrollPadding => searchTokens!.scrollPadding;
}

/// Convenience accessor for [TilawaInputStyle].
extension TilawaInputStyleX on BuildContext {
  TilawaInputStyle inputStyle({
    TilawaInputRole role = TilawaInputRole.form,
    double? fieldHeight,
  }) => TilawaInputStyle.of(this, role: role, fieldHeight: fieldHeight);
}
