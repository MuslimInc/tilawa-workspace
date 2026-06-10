import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
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
    final designTokens = theme.tokens;
    final double groupRadius = designTokens.resolveRadius(
      family: TilawaRadiusFamily.chrome,
    );

    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.groupSurfaceColor,
          borderRadius: BorderRadius.circular(groupRadius),
          border: Border.all(
            color: tokens.groupContainerBorderColor,
            width: tokens.tileDividerThickness,
          ),
          boxShadow: tokens.groupShadowOpacity > 0
              ? [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(
                      alpha: tokens.groupShadowOpacity * 0.5,
                    ),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                  BoxShadow(
                    color: colorScheme.shadow.withValues(
                      alpha: tokens.groupShadowOpacity,
                    ),
                    blurRadius: tokens.groupShadowBlur,
                    offset: tokens.groupShadowOffset,
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++)
              TilawaSettingsGroupRowStyle(
                borderRadius: tilawaSettingsGroupRowBorderRadius(
                  index: i,
                  rowCount: children.length,
                  radius: groupRadius,
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
    this.leadingIcon,
    this.includeTopGap = true,
  });

  final String title;
  final List<Widget> children;
  final IconData? leadingIcon;

  /// Adds [TilawaDesignTokens.spaceXXL] above the section header.
  final bool includeTopGap;

  @override
  Widget build(BuildContext context) {
    final topGap = includeTopGap ? Theme.of(context).tokens.spaceXXL : 0.0;

    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: TilawaSettingsGroupHorizontalInset(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TilawaSectionHeader.settings(
              context,
              title: title,
              leadingIcon: leadingIcon,
            ),
            TilawaSettingsGroupPanel(children: children),
          ],
        ),
      ),
    );
  }
}
