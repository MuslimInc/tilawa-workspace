import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../molecules/tilawa_section_header.dart';

/// Rounded panel for settings rows (profile header, grouped tiles).
class TilawaSettingsGroupPanel extends StatelessWidget {
  const TilawaSettingsGroupPanel({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.componentTokens.settingsGroup;

    return SizedBox(
      width: double.infinity,
      child: Container(
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
    );
  }
}

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TilawaSectionHeader.settings(context, title: title),
        TilawaSettingsGroupPanel(children: children),
      ],
    );
  }
}
