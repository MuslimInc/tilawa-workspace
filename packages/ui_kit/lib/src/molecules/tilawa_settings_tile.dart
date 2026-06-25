import 'package:flutter/material.dart';

import '../atoms/tilawa_switch.dart';
import '../foundation/component_tokens.dart';
import '../foundation/tilawa_text_roles.dart';
import '../foundation/tilawa_icons.dart';
import '../foundation/design_tokens.dart';
import 'tilawa_settings_group_row_style.dart';
import 'tilawa_settings_list_row.dart';

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

EdgeInsetsGeometry _settingsListRowPadding(
  BuildContext context,
  MeMuslimDesignTokens designTokens,
) {
  return EdgeInsetsDirectional.only(
    start: designTokens.spaceSmall,
    end: designTokens.spaceSmall,
  );
}

class TilawaSettingsTile extends StatelessWidget {
  const TilawaSettingsTile({
    super.key,
    this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconColor,
    this.showDivider = true,
    this.borderRadius = BorderRadius.zero,
    this.trailing,
  });

  final IconData? icon;
  final Color? iconColor;
  final String title;
  final VoidCallback onTap;

  /// Optional supporting copy shown under [title].
  ///
  /// Use this for calm settings context that prevents ambiguity, such as
  /// explaining a privacy or download preference without a custom row layout.
  final String? subtitle;

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

    return Column(
      children: [
        TilawaSettingsListRow(
          semanticLabel: title,
          borderRadius: resolvedRadius,
          contentPadding: _settingsListRowPadding(context, designTokens),
          minTileHeight: designTokens.minInteractiveDimension,
          rowGap: tokens.tileItemGap,
          onTap: onTap,
          leading: icon == null
              ? null
              : _SettingsLeadingIcon(
                  icon: icon!,
                  color: effectiveIconColor,
                  tokens: tokens,
                ),
          title: _SettingsTileLabel(
            title,
            subtitle: subtitle,
            tokens: tokens,
          ),
          trailing:
              trailing ??
              Icon(
                TilawaIcons.chevronRightSmall,
                size: tokens.tileTrailingSize,
                color: colorScheme.onSurfaceVariant.withValues(
                  alpha: tokens.tileTrailingOpacity,
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
    this.subtitle,
    this.iconColor,
    this.showDivider = true,
    this.borderRadius = BorderRadius.zero,
  });

  final IconData? icon;
  final Color? iconColor;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Optional supporting copy shown under [title].
  final String? subtitle;

  final bool showDivider;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.settingsGroup;
    final designTokens = theme.tokens;
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;
    final BorderRadius resolvedRadius = _resolveSettingsTileBorderRadius(
      context,
      borderRadius,
    );

    return Column(
      children: [
        TilawaSettingsListRow(
          semanticLabel: title,
          borderRadius: resolvedRadius,
          contentPadding: _settingsListRowPadding(context, designTokens),
          minTileHeight: designTokens.minInteractiveDimension,
          rowGap: tokens.tileItemGap,
          onTap: () => onChanged(!value),
          toggled: value,
          leading: icon == null
              ? null
              : _SettingsLeadingIcon(
                  icon: icon!,
                  color: effectiveIconColor,
                  tokens: tokens,
                ),
          title: _SettingsTileLabel(
            title,
            subtitle: subtitle,
            tokens: tokens,
          ),
          trailing: TilawaSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: tokens.switchActiveTrackColor,
            activeThumbColor: tokens.switchActiveThumbColor,
            layoutSlotHeight: tokens.tileTrailingSize,
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

class _SettingsTileLabel extends StatelessWidget {
  const _SettingsTileLabel(
    this.title, {
    required this.tokens,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final TilawaSettingsGroupTokens tokens;

  @override
  Widget build(BuildContext context) {
    final subtitleText = subtitle;
    if (subtitleText == null || subtitleText.isEmpty) {
      return _SettingsTileTitle(
        title,
        tokens: tokens,
      );
    }

    return _SettingsTileTitleStack(
      title: title,
      subtitle: subtitleText,
      tokens: tokens,
    );
  }
}

class _SettingsTileTitleStack extends StatelessWidget {
  const _SettingsTileTitleStack({
    required this.title,
    required this.subtitle,
    required this.tokens,
  });

  final String title;
  final String subtitle;
  final TilawaSettingsGroupTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.tileSubtitleSpacing,
      children: [
        _SettingsTileTitle(
          title,
          tokens: tokens,
        ),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.start,
          style: _subtitleStyle(context, tokens),
        ),
      ],
    );
  }
}

class _SettingsTileTitle extends StatelessWidget {
  const _SettingsTileTitle(
    this.title, {
    required this.tokens,
  });

  final String title;
  final TilawaSettingsGroupTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.start,
      style: _titleStyle(context, tokens),
    );
  }
}

TextStyle _titleStyle(
  BuildContext context,
  TilawaSettingsGroupTokens tokens,
) {
  final theme = Theme.of(context);
  return tilawaResolveTextRole(
    theme.textTheme,
    tokens.tileTitleTextRole,
  ).copyWith(
    fontWeight: FontWeight.w600,
    color: theme.colorScheme.onSurface,
    height: 1.2,
  );
}

TextStyle _subtitleStyle(
  BuildContext context,
  TilawaSettingsGroupTokens tokens,
) {
  final theme = Theme.of(context);
  return tilawaResolveTextRole(
    theme.textTheme,
    tokens.tileSubtitleTextRole,
  ).copyWith(
    fontWeight: FontWeight.w400,
    color: theme.colorScheme.onSurfaceVariant.withValues(
      alpha: tokens.tileSubtitleOpacity,
    ),
    height: 1.35,
  );
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
    final designTokens = Theme.of(context).tokens;
    return Container(
      padding: tokens.tileIconPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: tokens.tileIconContainerOpacity),
        borderRadius: BorderRadius.circular(
          designTokens.resolveRadius(family: TilawaRadiusFamily.decorative),
        ),
      ),
      child: Icon(icon, color: color, size: tokens.tileIconSize),
    );
  }
}
