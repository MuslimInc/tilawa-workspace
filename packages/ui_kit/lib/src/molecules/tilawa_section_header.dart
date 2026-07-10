import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import '../foundation/tilawa_text_roles.dart';

/// Shared heading for grouped settings and form-like screens.
///
/// Styling defaults come from [TilawaSettingsGroupTokens]; pass [padding],
/// [titleTextStyle], or [subtitleTextStyle] only to deviate from the standard
/// section heading look.
class TilawaSectionHeader extends StatelessWidget {
  const TilawaSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailing,
    this.padding,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.bottom,
  });

  /// Heading styled like [TilawaSettingsGroup] section titles.
  ///
  /// Kept for source compatibility — the unnamed constructor now applies the
  /// same token-driven defaults, so this simply forwards.
  factory TilawaSectionHeader.settings(
    BuildContext context, {
    required String title,
    String? subtitle,
    IconData? leadingIcon,
    Widget? trailing,
    Widget? bottom,
  }) {
    return TilawaSectionHeader(
      title: title,
      subtitle: subtitle,
      leadingIcon: leadingIcon,
      trailing: trailing,
      bottom: bottom,
    );
  }

  final String title;
  final IconData? leadingIcon;
  final String? subtitle;
  final Widget? trailing;

  /// Outer insets. Defaults to [TilawaSettingsGroupTokens.groupHeaderPadding].
  final EdgeInsetsGeometry? padding;

  /// Title style. Defaults to `titleSmall` shaped by
  /// [TilawaSettingsGroupTokens] font size and letter spacing.
  final TextStyle? titleTextStyle;

  /// Subtitle style. Defaults to `bodySmall` in `onSurfaceVariant`.
  final TextStyle? subtitleTextStyle;

  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final groupTokens = theme.componentTokens.settingsGroup;

    final TextStyle effectiveTitleStyle =
        titleTextStyle ??
        tilawaResolveTextRole(
          theme.textTheme,
          groupTokens.groupTitleTextRole,
        ).copyWith(
          fontWeight: FontWeight.w800,
          height: 1.15,
          color: colorScheme.onSurface,
          letterSpacing: groupTokens.groupTitleLetterSpacing,
        );

    final TextStyle? effectiveSubtitleStyle =
        subtitleTextStyle ??
        theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        );

    return Padding(
      padding: padding ?? groupTokens.groupHeaderPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: tokens.spaceSmall,
                        children: [
                          if (leadingIcon != null) ...[
                            Icon(
                              leadingIcon,
                              size: tokens.iconSizeSmall,
                              color: colorScheme.onSurface,
                            ),
                          ],
                          Flexible(
                            child: Text(
                              title,
                              style: effectiveTitleStyle,
                              textAlign: TextAlign.start,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (subtitle != null && effectiveSubtitleStyle != null) ...[
                      SizedBox(height: tokens.spaceExtraSmall),
                      Text(
                        subtitle!,
                        style: effectiveSubtitleStyle,
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          ?bottom,
        ],
      ),
    );
  }
}
