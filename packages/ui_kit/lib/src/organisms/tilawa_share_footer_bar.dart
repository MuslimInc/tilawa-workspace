import 'package:flutter/material.dart';

import '../foundation/component_tokens/component_tokens_theme.dart';
import '../foundation/tilawa_text_roles.dart';

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
    // fix: Consistency & standards — respect ambient directionality (no RTL hardcode)
    // fix: Visual hierarchy — derive styles from text theme roles
    final TextStyle primaryStyle =
        tilawaResolveTextRole(
          textTheme,
          tokens.primaryLabelTextRole,
        ).copyWith(
          fontWeight: tokens.labelFontWeight,
          color: resolvedForegroundColor,
          decoration: TextDecoration.none,
          decorationColor: Colors.transparent,
        );
    final TextStyle secondaryStyle =
        tilawaResolveTextRole(
          textTheme,
          tokens.secondaryLabelTextRole,
        ).copyWith(
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
                  textAlign: TextAlign.end,
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
