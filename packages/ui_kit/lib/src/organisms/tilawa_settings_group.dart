import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../molecules/tilawa_section_header.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TilawaSectionHeader.settings(context, title: title),
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
