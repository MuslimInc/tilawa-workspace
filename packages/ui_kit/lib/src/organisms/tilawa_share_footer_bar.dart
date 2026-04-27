import 'package:flutter/material.dart';

import '../foundation/component_tokens/component_tokens_theme.dart';

class TilawaShareFooterBar extends StatelessWidget {
  const TilawaShareFooterBar({
    super.key,
    required this.primaryLabel,
    required this.secondaryLabel,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String primaryLabel;
  final String secondaryLabel;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.footerBar;
    final textTheme = theme.textTheme;
    final Color resolvedBackgroundColor =
        backgroundColor ?? theme.colorScheme.secondaryContainer;
    final Color resolvedForegroundColor =
        foregroundColor ??
        (ThemeData.estimateBrightnessForColor(resolvedBackgroundColor) ==
                Brightness.dark
            ? theme.colorScheme.onSecondaryContainer
            : theme.colorScheme.onSurface);
    final TextStyle primaryStyle = (textTheme.titleSmall ?? const TextStyle())
        .copyWith(
          fontSize: tokens.labelFontSize,
          fontWeight: tokens.labelFontWeight,
          color: resolvedForegroundColor,
          decoration: TextDecoration.none,
          decorationColor: Colors.transparent,
        );
    final TextStyle secondaryStyle = (textTheme.bodySmall ?? const TextStyle())
        .copyWith(
          fontSize: tokens.secondaryLabelFontSize,
          color: resolvedForegroundColor.withValues(
            alpha: tokens.secondaryLabelOpacity,
          ),
          decoration: TextDecoration.none,
          decorationColor: Colors.transparent,
        );

    return DecoratedBox(
      decoration: BoxDecoration(color: resolvedBackgroundColor),
      child: SizedBox(
        height: tokens.height,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.horizontalPadding),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  primaryLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.start,
                  style: primaryStyle,
                ),
              ),
              SizedBox(width: tokens.contentGap),
              Flexible(
                child: Text(
                  secondaryLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: secondaryStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
