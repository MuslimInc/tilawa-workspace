import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../atoms/tilawa_switch.dart';
import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import 'tilawa_settings_group_row_style.dart';

BorderRadius _resolveSettingsTileBorderRadius(
  BuildContext context,
  BorderRadiusGeometry borderRadius,
) {
  if (borderRadius != BorderRadius.zero) {
    return borderRadius.resolve(Directionality.of(context));
  }

  return TilawaSettingsGroupRowStyle.maybeOf(context)?.borderRadius ??
      BorderRadius.zero;
}

class TilawaSettingsTile extends StatelessWidget {
  const TilawaSettingsTile({
    super.key,
    this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.showDivider = true,
    this.borderRadius = BorderRadius.zero,
    this.trailing,
  });

  final IconData? icon;
  final Color? iconColor;
  final String title;
  final VoidCallback onTap;
  final bool showDivider;
  final BorderRadiusGeometry borderRadius;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.componentTokens.settingsGroup;
    final designTokens = theme.tokens;
    final effectiveIconColor = iconColor ?? colorScheme.primary;
    final BorderRadius resolvedRadius = _resolveSettingsTileBorderRadius(
      context,
      borderRadius,
    );
    final TextDirection direction = Directionality.of(context);
    final EdgeInsets resolvedContentPadding = tokens.tileContentPadding.resolve(
      direction,
    );
    final EdgeInsetsGeometry listTileContentPadding =
        EdgeInsetsDirectional.only(
          start: designTokens.spaceSmall,
          end: designTokens.spaceSmall,
        );
    final EdgeInsets resolvedIconPadding = tokens.tileIconPadding.resolve(
      direction,
    );
    final double minLeadingWidth = icon == null
        ? 0
        : resolvedIconPadding.horizontal + tokens.tileIconSize;
    final TextStyle titleStyle =
        theme.textTheme.bodyLarge?.copyWith(
          fontSize: tokens.tileTitleFontSize,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          height: 1.2,
        ) ??
        TextStyle(
          fontSize: tokens.tileTitleFontSize,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          height: 1.2,
        );
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: resolvedRadius,
          clipBehavior: Clip.antiAlias,
          child: ListTileTheme(
            data: ListTileThemeData(
              contentPadding: resolvedContentPadding,
              horizontalTitleGap: tokens.tileItemGap,
              minLeadingWidth: minLeadingWidth,
              minTileHeight: designTokens.minInteractiveDimension,
              minVerticalPadding: 0,
              titleTextStyle: titleStyle,
            ),
            child: ListTile(
              minTileHeight: designTokens.minInteractiveDimension,
              contentPadding: listTileContentPadding,
              shape: RoundedRectangleBorder(borderRadius: resolvedRadius),
              leading: icon == null
                  ? null
                  : _SettingsLeadingIcon(
                      icon: icon!,
                      color: effectiveIconColor,
                      tokens: tokens,
                    ),
              title: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
              ),
              trailing:
                  trailing ??
                  // Right chevron; ListTile still places trailing on the
                  // correct edge in RTL.
                  Icon(
                    FluentIcons.chevron_right_20_regular,
                    size: tokens.tileTrailingSize,
                    color: colorScheme.onSurfaceVariant.withValues(
                      alpha: (tokens.tileTrailingOpacity * 1.35).clamp(
                        0.45,
                        0.72,
                      ),
                    ),
                  ),
              onTap: onTap,
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: tokens.tileDividerPadding,
            child: Divider(
              height: tokens.tileDividerHeight,
              thickness: tokens.tileDividerThickness,
              color: tokens.selectionTileDividerColor,
            ),
          ),
      ],
    );
  }
}

class TilawaSettingsSwitchTile extends StatelessWidget {
  const TilawaSettingsSwitchTile({
    super.key,
    this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.iconColor,
    this.showDivider = true,
    this.borderRadius = BorderRadius.zero,
  });

  final IconData? icon;
  final Color? iconColor;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.componentTokens.settingsGroup;
    final designTokens = theme.tokens;
    final effectiveIconColor = iconColor ?? colorScheme.primary;
    final BorderRadius resolvedRadius = _resolveSettingsTileBorderRadius(
      context,
      borderRadius,
    );
    final TextDirection direction = Directionality.of(context);
    final EdgeInsets resolvedContentPadding = tokens.switchTileContentPadding
        .resolve(direction);
    final EdgeInsetsGeometry listTileContentPadding =
        EdgeInsetsDirectional.only(
          start: designTokens.spaceSmall,
          end: designTokens.spaceSmall,
        );
    final EdgeInsets resolvedIconPadding = tokens.tileIconPadding.resolve(
      direction,
    );
    final double minLeadingWidth = icon == null
        ? 0
        : resolvedIconPadding.horizontal + tokens.tileIconSize;
    final TextStyle titleStyle =
        theme.textTheme.bodyLarge?.copyWith(
          fontSize: tokens.tileTitleFontSize,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          height: 1.2,
        ) ??
        TextStyle(
          fontSize: tokens.tileTitleFontSize,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          height: 1.2,
        );
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: resolvedRadius,
          clipBehavior: Clip.antiAlias,
          child: ListTileTheme(
            data: ListTileThemeData(
              contentPadding: resolvedContentPadding,
              horizontalTitleGap: tokens.tileItemGap,
              minLeadingWidth: minLeadingWidth,
              minTileHeight: designTokens.minInteractiveDimension,
              minVerticalPadding: 0,
              titleTextStyle: titleStyle,
            ),
            child: ListTile(
              minTileHeight: designTokens.minInteractiveDimension,
              contentPadding: listTileContentPadding,
              shape: RoundedRectangleBorder(borderRadius: resolvedRadius),
              leading: icon == null
                  ? null
                  : _SettingsLeadingIcon(
                      icon: icon!,
                      color: effectiveIconColor,
                      tokens: tokens,
                    ),
              title: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
                style: titleStyle,
              ),
              trailing: TilawaSwitch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: tokens.switchActiveTrackColor,
                activeThumbColor: tokens.switchActiveThumbColor,
                layoutSlotHeight: tokens.tileTrailingSize,
              ),
              onTap: () => onChanged(!value),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: tokens.tileDividerPadding,
            child: Divider(
              height: tokens.tileDividerHeight,
              thickness: tokens.tileDividerThickness,
              color: tokens.selectionTileDividerColor,
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
