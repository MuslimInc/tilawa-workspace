import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../molecules/tilawa_section_header.dart';
import '../molecules/tilawa_settings_group_row_style.dart';

/// Applies the screen-edge horizontal inset shared by settings groups.
class TilawaSettingsGroupHorizontalInset extends StatelessWidget {
  const TilawaSettingsGroupHorizontalInset({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final padding = Theme.of(context).componentTokens.settingsGroup
        .groupHorizontalPadding;

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: padding),
      child: child,
    );
  }
}

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
            // Ambient layer — gives the panel a crisp "lifted card" edge.
            BoxShadow(
              color: colorScheme.shadow.withValues(
                alpha: tokens.groupShadowOpacity * 0.5,
              ),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
            // Directional layer — main depth cue from overhead light.
            BoxShadow(
              color: colorScheme.shadow.withValues(
                alpha: tokens.groupShadowOpacity,
              ),
              blurRadius: tokens.groupShadowBlur,
              offset: tokens.groupShadowOffset,
            ),
          ],
        ),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++)
              TilawaSettingsGroupRowStyle(
                borderRadius: tilawaSettingsGroupRowBorderRadius(
                  index: i,
                  rowCount: children.length,
                  radius: tokens.groupBorderRadius,
                ),
                child: children[i],
              ),
          ],
        ),
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
    return TilawaSettingsGroupHorizontalInset(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TilawaSectionHeader.settings(context, title: title),
          TilawaSettingsGroupPanel(children: children),
        ],
      ),
    );
  }
}
