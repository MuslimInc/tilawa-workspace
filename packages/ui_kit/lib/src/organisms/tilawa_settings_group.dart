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
    final tokens = theme.componentTokens.settingsGroup;

    return Column(
      crossAxisAlignment: .start,
      children: [
        Padding(
          padding: tokens.groupHeaderPadding,
          child: Text(
            title,
            style: TextStyle(
              fontSize: tokens.groupTitleFontSize,
              fontWeight: .w800,
              color: theme.primaryColor,
              letterSpacing: tokens.groupTitleLetterSpacing,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(tokens.groupBorderRadius),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(
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
