import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

/// Visual slot for [Switch.adaptive] in settings rows. M3 switches request
/// about 52x40 dp plus theme padding; fitting to this box keeps [ListTile] at
/// [TilawaDesignTokens.minInteractiveDimension] without inflating the row.
const Size _kSettingsSwitchSlotSize = Size(48, 30);

class TilawaSettingsTile extends StatelessWidget {
  const TilawaSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.showDivider = true,
    this.borderRadius = BorderRadius.zero,
    this.trailing,
  });

  final IconData icon;
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
    final BorderRadius? resolvedRadius = borderRadius is BorderRadius
        ? borderRadius as BorderRadius
        : null;
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
    final double minLeadingWidth =
        resolvedIconPadding.horizontal + tokens.tileIconSize;
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
    final TextStyle subtitleStyle =
        theme.textTheme.bodySmall?.copyWith(
          fontSize: tokens.tileSubtitleFontSize,
          color: colorScheme.onSurfaceVariant.withValues(
            alpha: tokens.tileSubtitleOpacity.clamp(0.55, 0.85),
          ),
          height: 1.35,
        ) ??
        TextStyle(
          fontSize: tokens.tileSubtitleFontSize,
          color: colorScheme.onSurfaceVariant.withValues(
            alpha: tokens.tileSubtitleOpacity.clamp(0.55, 0.85),
          ),
        );

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          child: ListTileTheme(
            data: ListTileThemeData(
              contentPadding: resolvedContentPadding,
              horizontalTitleGap: tokens.tileItemGap,
              minLeadingWidth: minLeadingWidth,
              minTileHeight: designTokens.minInteractiveDimension,
              minVerticalPadding: 0,
              titleTextStyle: titleStyle,
              subtitleTextStyle: subtitleStyle,
            ),
            child: ListTile(
              minTileHeight: designTokens.minInteractiveDimension,
              contentPadding: listTileContentPadding,
              shape: resolvedRadius != null
                  ? RoundedRectangleBorder(borderRadius: resolvedRadius)
                  : null,
              leading: _SettingsLeadingIcon(
                icon: icon,
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
                    FluentIcons.chevron_right_24_filled,
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
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.iconColor,
    this.showDivider = true,
    this.borderRadius = BorderRadius.zero,
  });

  final IconData icon;
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
    final BorderRadius? resolvedRadius = borderRadius is BorderRadius
        ? borderRadius as BorderRadius
        : null;
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
    final double minLeadingWidth =
        resolvedIconPadding.horizontal + tokens.tileIconSize;
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
    final TextStyle subtitleStyle =
        theme.textTheme.bodySmall?.copyWith(
          fontSize: tokens.tileSubtitleFontSize,
          color: colorScheme.onSurfaceVariant.withValues(
            alpha: tokens.tileSubtitleOpacity.clamp(0.55, 0.85),
          ),
          height: 1.35,
        ) ??
        TextStyle(
          fontSize: tokens.tileSubtitleFontSize,
          color: colorScheme.onSurfaceVariant.withValues(
            alpha: tokens.tileSubtitleOpacity.clamp(0.55, 0.85),
          ),
        );

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          child: ListTileTheme(
            data: ListTileThemeData(
              contentPadding: resolvedContentPadding,
              horizontalTitleGap: tokens.tileItemGap,
              minLeadingWidth: minLeadingWidth,
              minTileHeight: designTokens.minInteractiveDimension,
              minVerticalPadding: 0,
              titleTextStyle: titleStyle,
              subtitleTextStyle: subtitleStyle,
            ),
            child: ListTile(
              minTileHeight: designTokens.minInteractiveDimension,
              contentPadding: listTileContentPadding,
              visualDensity: VisualDensity.compact,
              titleAlignment: ListTileTitleAlignment.center,
              shape: resolvedRadius != null
                  ? RoundedRectangleBorder(borderRadius: resolvedRadius)
                  : null,
              leading: _SettingsLeadingIcon(
                icon: icon,
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
              trailing: Theme(
                data: theme.copyWith(
                  switchTheme: theme.switchTheme.copyWith(
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                child: SizedBox(
                  width: _kSettingsSwitchSlotSize.width,
                  height: _kSettingsSwitchSlotSize.height,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    child: Switch.adaptive(
                      value: value,
                      onChanged: onChanged,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      activeTrackColor: tokens.switchActiveTrackColor,
                      activeThumbColor: tokens.switchActiveThumbColor,
                    ),
                  ),
                ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: tokens.tileIconPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: tokens.tileIconContainerOpacity),
        borderRadius: BorderRadius.circular(tokens.tileIconBorderRadius),
      ),
      child: Icon(icon, color: color, size: tokens.tileIconSize),
    );
  }
}
