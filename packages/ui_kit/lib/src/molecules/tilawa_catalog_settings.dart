import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../atoms/tilawa_switch.dart';
import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

/// Pinterest-style settings section: bold title, flat rows (no card).
class TilawaCatalogSettingsSection extends StatelessWidget {
  const TilawaCatalogSettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.topSpacing,
  });

  final String title;
  final List<Widget> children;
  final double? topSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: topSpacing ?? tokens.spaceLarge),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            tokens.spaceMedium,
            0,
            tokens.spaceMedium,
            tokens.spaceSmall,
          ),
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

/// Flat tappable settings row (label + optional trailing + chevron).
class TilawaCatalogSettingsLinkRow extends StatelessWidget {
  const TilawaCatalogSettingsLinkRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.titleColor,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    final TextStyle titleStyle = theme.textTheme.bodyLarge!.copyWith(
      fontWeight: FontWeight.w600,
      color: titleColor ?? colorScheme.onSurface,
      height: 1.25,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            tokens.spaceMedium,
            tokens.spaceSmall + tokens.spaceTiny,
            tokens.spaceMedium,
            tokens.spaceSmall + tokens.spaceTiny,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: titleStyle),
                    if (subtitle != null) ...[
                      SizedBox(height: tokens.spaceTiny),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: tokens.opacityEmphasis,
                          ),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                SizedBox(width: tokens.spaceSmall),
              ],
              if (showChevron && onTap != null)
                Icon(
                  FluentIcons.chevron_right_20_regular,
                  size: 20,
                  color: colorScheme.onSurface.withValues(
                    alpha: tokens.opacityEmphasis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Flat row with a trailing [TilawaSwitch] (no chevron).
class TilawaCatalogSettingsSwitchRow extends StatelessWidget {
  const TilawaCatalogSettingsSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final switchTokens = theme.componentTokens.settingsGroup;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            tokens.spaceMedium,
            tokens.spaceSmall + tokens.spaceTiny,
            tokens.spaceMedium,
            tokens.spaceSmall + tokens.spaceTiny,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    height: 1.25,
                  ),
                ),
              ),
              TilawaSwitch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: switchTokens.switchActiveTrackColor,
                activeThumbColor: switchTokens.switchActiveThumbColor,
                layoutSlotHeight: tokens.iconSizeMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Profile header row for catalog settings (avatar + title + subtitle).
class TilawaCatalogSettingsProfileRow extends StatelessWidget {
  const TilawaCatalogSettingsProfileRow({
    super.key,
    required this.avatar,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final Widget avatar;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceMedium,
            tokens.spaceMedium,
            tokens.spaceMedium,
            tokens.spaceSmall,
          ),
          child: Row(
            children: [
              avatar,
              SizedBox(width: tokens.spaceMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: tokens.spaceTiny),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: tokens.opacityEmphasis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  FluentIcons.chevron_right_20_regular,
                  size: 20,
                  color: colorScheme.onSurface.withValues(
                    alpha: tokens.opacityEmphasis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Centered max-width column for settings on tablet (optional wrapper).
class TilawaCatalogSettingsBody extends StatelessWidget {
  const TilawaCatalogSettingsBody({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: tokens.contentMaxWidthMedia),
        child: child,
      ),
    );
  }
}
