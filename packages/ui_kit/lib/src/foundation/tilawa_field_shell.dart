import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'tilawa_input_style.dart';

/// Shared chrome shell for kit inputs.
///
/// [TilawaFieldShell.decorator] — [InputDecorator] owns the border (form,
/// dropdown, read-only selectors).
///
/// [TilawaFieldShell.search] — outer [BoxDecoration] owns the border; the child
/// must use [TilawaInputStyle.borderlessDecoration].
class TilawaFieldShell extends StatelessWidget {
  const TilawaFieldShell.decorator({
    super.key,
    required this.decoration,
    required this.child,
    this.onTap,
    this.isEmpty = false,
    this.semanticLabel,
    this.minHeight,
  }) : style = null,
       isFocused = false,
       hasError = false,
       backgroundColor = null,
       showShadow = false,
       borderRadiusOverride = null,
       useCatalogBorderColors = true,
       margin = null,
       shellHeight = null,
       shellConstraints = null;

  const TilawaFieldShell.search({
    super.key,
    required this.style,
    required this.child,
    required this.isFocused,
    required this.hasError,
    this.backgroundColor,
    this.showShadow = false,
    this.borderRadiusOverride,
    this.useCatalogBorderColors = true,
    this.margin,
    this.shellHeight,
    this.shellConstraints,
  }) : decoration = null,
       onTap = null,
       isEmpty = false,
       semanticLabel = null,
       minHeight = null;

  final InputDecoration? decoration;
  final TilawaInputStyle? style;
  final Widget child;
  final VoidCallback? onTap;
  final bool isEmpty;
  final String? semanticLabel;
  final double? minHeight;

  final bool isFocused;
  final bool hasError;
  final Color? backgroundColor;
  final bool showShadow;
  final BorderRadiusGeometry? borderRadiusOverride;
  final bool useCatalogBorderColors;
  final EdgeInsetsGeometry? margin;
  final double? shellHeight;
  final BoxConstraints? shellConstraints;

  bool get _isSearch => style != null;

  @override
  Widget build(BuildContext context) {
    if (_isSearch) {
      return _buildSearchShell(context);
    }
    return _buildDecoratorShell(context);
  }

  Widget _buildDecoratorShell(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    Widget field = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: minHeight ?? tokens.minInteractiveDimension,
      ),
      child: InputDecorator(
        decoration: decoration!,
        isEmpty: isEmpty,
        child: child,
      ),
    );

    if (onTap != null) {
      final double radius = decoration!.border is OutlineInputBorder
          ? (decoration!.border! as OutlineInputBorder).borderRadius
                .resolve(TextDirection.ltr)
                .topLeft
                .x
          : tokens.resolveRadius(family: TilawaRadiusFamily.chrome);
      field = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: field,
      );
    }

    if (semanticLabel != null) {
      field = Semantics(
        button: onTap != null,
        label: semanticLabel,
        child: field,
      );
    }

    return field;
  }

  Widget _buildSearchShell(BuildContext context) {
    final TilawaInputStyle inputStyle = style!;

    return Container(
      height: shellHeight,
      constraints: shellConstraints,
      margin: margin,
      decoration: inputStyle.searchShellDecoration(
        isFocused: isFocused,
        hasError: hasError,
        backgroundColor: backgroundColor,
        borderRadiusOverride: borderRadiusOverride,
        showShadow: showShadow,
        useCatalogBorderColors: useCatalogBorderColors,
      ),
      child: child,
    );
  }
}
