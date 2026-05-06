import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';

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
    final colorScheme = theme.colorScheme;
    final tokens = theme.componentTokens.settingsGroup;
    final effectiveIconColor = iconColor ?? colorScheme.primary;
    final trailingIcon = Directionality.of(context) == TextDirection.rtl
        ? FluentIcons.chevron_left_24_filled
        : FluentIcons.chevron_right_24_filled;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius is BorderRadius
                ? borderRadius as BorderRadius
                : null,
            child: Padding(
              padding: tokens.tileContentPadding,
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
                      crossAxisAlignment: .start,
                      spacing: tokens.tileSubtitleSpacing,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: tokens.tileTitleFontSize,
                            fontWeight: .w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: tokens.tileSubtitleFontSize,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: tokens.tileSubtitleOpacity,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  trailing ??
                      Icon(
                        trailingIcon,
                        size: tokens.tileTrailingSize,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: tokens.tileTrailingOpacity,
                        ),
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
              color: colorScheme.outlineVariant.withValues(
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
    final colorScheme = theme.colorScheme;
    final tokens = theme.componentTokens.settingsGroup;
    final effectiveIconColor = iconColor ?? colorScheme.primary;

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
                      crossAxisAlignment: .start,
                      spacing: tokens.tileSubtitleSpacing,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: tokens.tileTitleFontSize,
                            fontWeight: .w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: tokens.tileSubtitleFontSize,
                              color: colorScheme.onSurfaceVariant.withValues(
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
                    activeTrackColor: colorScheme.primary.withValues(
                      alpha: tokens.switchActiveTrackOpacity,
                    ),
                    activeThumbColor: colorScheme.primary,
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
              color: colorScheme.outlineVariant.withValues(
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
