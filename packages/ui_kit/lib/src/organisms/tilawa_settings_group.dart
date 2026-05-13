import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';

class TilawaSettingsGroup extends StatelessWidget {
  const TilawaSettingsGroup({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.componentTokens.settingsGroup;

    final TextStyle? sectionStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      height: 1.25,
      color: colorScheme.onSurface,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: tokens.groupHeaderPadding,
          child: Text(
            title,
            style:
                sectionStyle?.copyWith(
                  fontSize: tokens.groupTitleFontSize,
                  letterSpacing: tokens.groupTitleLetterSpacing,
                ) ??
                TextStyle(
                  fontSize: tokens.groupTitleFontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: tokens.groupTitleLetterSpacing,
                  color: colorScheme.onSurface,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: tokens.groupSurfaceColor,
            borderRadius: BorderRadius.circular(tokens.groupBorderRadius),
            border: Border.all(
              color: tokens.groupContainerBorderColor,
              width: tokens.tileDividerThickness,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(
                  alpha: tokens.groupShadowOpacity,
                ),
                blurRadius: tokens.groupShadowBlur,
                offset: tokens.groupShadowOffset,
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
