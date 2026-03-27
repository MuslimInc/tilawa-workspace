import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';

class TilawaSheetHandle extends StatelessWidget {
  const TilawaSheetHandle({
    super.key,
    this.width,
    this.height,
    this.margin,
    this.color,
  });

  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final componentTokens = theme.componentTokens.sheetHandle;

    return Center(
      child: Container(
        width: width ?? componentTokens.width,
        height: height ?? componentTokens.height,
        margin: margin ?? EdgeInsets.only(bottom: componentTokens.marginBottom),
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
