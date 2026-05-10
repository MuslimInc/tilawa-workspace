import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';

class TilawaSheetHandle extends StatelessWidget {
  const TilawaSheetHandle({
    super.key,
    this.showHandle = true,
    this.width,
    this.height,
    this.margin,
    this.color,
    this.omitTopMargin = false,
  });

  final bool showHandle;
  final double? width;
  final double? height;

  /// When null, uses token [TilawaSheetHandleTokens.marginTop] and
  /// [TilawaSheetHandleTokens.marginBottom]. When set, replaces that default
  /// entirely.
  final EdgeInsetsGeometry? margin;
  final Color? color;

  /// When true and [margin] is null, top inset is zero so a parent
  /// ([Positioned], padding, etc.) can own vertical placement; bottom still
  /// uses the token.
  final bool omitTopMargin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final componentTokens = theme.componentTokens.sheetHandle;
    if (!showHandle) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Container(
        width: width ?? componentTokens.width,
        height: height ?? componentTokens.height,
        margin:
            margin ??
            EdgeInsets.only(
              top: omitTopMargin ? 0 : componentTokens.marginTop,
              bottom: componentTokens.marginBottom,
            ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(componentTokens.cornerRadius),
          color:
              color ??
              theme.colorScheme.onSurface.withValues(
                alpha: componentTokens.colorOpacity,
              ),
        ),
      ),
    );
  }
}
