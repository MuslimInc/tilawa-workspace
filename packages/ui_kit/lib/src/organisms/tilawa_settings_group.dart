import 'package:fluentui_system_icons/fluentui_system_icons.dart';
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: tokens.groupHeaderPadding,
          child: Text(
            title,
            style: TextStyle(
              fontSize: tokens.groupTitleFontSize,
              fontWeight: FontWeight.w800,
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
                color: Colors.black.withValues(
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

class TilawaSettingsTile extends StatelessWidget {
  const TilawaSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.subtitle,
    this.showDivider = true,
    this.borderRadius = BorderRadius.zero,
    this.trailing,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showDivider;
  final BorderRadiusGeometry borderRadius;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.settingsGroup;
    final effectiveIconColor = iconColor ?? theme.primaryColor;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: ListTile(
            onTap: onTap,
            contentPadding: tokens.tileContentPadding,
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            leading: _SettingsLeadingIcon(
              icon: icon,
              color: effectiveIconColor,
              tokens: tokens,
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: tokens.tileTitleFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: subtitle == null
                ? null
                : Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: tokens.tileSubtitleFontSize,
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: tokens.tileSubtitleOpacity,
                      ),
                    ),
                  ),
            trailing:
                trailing ??
                Icon(
                  FluentIcons.chevron_right_24_filled,
                  size: tokens.tileTrailingSize,
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: tokens.tileTrailingOpacity,
                  ),
                ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: tokens.tileDividerPadding,
            child: Divider(
              height: tokens.tileDividerHeight,
              thickness: tokens.tileDividerThickness,
              color: theme.dividerColor.withValues(
                alpha: tokens.tileDividerOpacity,
              ),
            ),
          ),
      ],
    );
  }
}

class TilawaSettingsSwitchTile extends StatelessWidget {
  const TilawaSettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.iconColor,
    this.subtitle,
    this.showDivider = true,
    this.borderRadius = BorderRadius.zero,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.settingsGroup;
    final effectiveIconColor = iconColor ?? theme.primaryColor;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            onTap: () => onChanged(!value),
            borderRadius: borderRadius is BorderRadius
                ? borderRadius as BorderRadius
                : null,
            child: Padding(
              padding: tokens.switchTileContentPadding,
              child: Row(
                spacing: tokens.tileItemGap,
                children: [
                  _SettingsLeadingIcon(
                    icon: icon,
                    color: effectiveIconColor,
                    tokens: tokens,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: tokens.tileSubtitleSpacing,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: tokens.tileTitleFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: tokens.tileSubtitleFontSize,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(
                                    alpha: tokens.tileSubtitleOpacity,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: value,
                    onChanged: onChanged,
                    activeTrackColor: theme.primaryColor.withValues(
                      alpha: tokens.switchActiveTrackOpacity,
                    ),
                    activeThumbColor: theme.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: tokens.tileDividerPadding,
            child: Divider(
              height: tokens.tileDividerHeight,
              thickness: tokens.tileDividerThickness,
              color: theme.dividerColor.withValues(
                alpha: tokens.tileDividerOpacity,
              ),
            ),
          ),
      ],
    );
  }
}

class _SettingsLeadingIcon extends StatelessWidget {
  const _SettingsLeadingIcon({
    required this.icon,
    required this.color,
    required this.tokens,
  });

  final IconData icon;
  final Color color;
  final TilawaSettingsGroupTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: tokens.tileIconPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: tokens.tileIconContainerOpacity),
        borderRadius: BorderRadius.circular(tokens.tileIconBorderRadius),
      ),
      child: Icon(icon, color: color, size: tokens.tileIconSize),
    );
  }
}
