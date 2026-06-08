import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

/// Shared heading for grouped settings and form-like screens.
///
/// Use [TilawaSectionHeader.settings] for the same layout and styles as the
/// former inline header in [TilawaSettingsGroup].
class TilawaSectionHeader extends StatelessWidget {
  const TilawaSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailing,
    required this.padding,
    required this.titleTextStyle,
    this.subtitleTextStyle,
    this.bottom,
  });

  /// Heading styled like [TilawaSettingsGroup] section titles.
  factory TilawaSectionHeader.settings(
    BuildContext context, {
    required String title,
    String? subtitle,
    IconData? leadingIcon,
    Widget? trailing,
    Widget? bottom,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.componentTokens.settingsGroup;

    final TextStyle? base = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.3,
      color: colorScheme.onSurface,
    );

    final TextStyle titleTextStyle =
        base?.copyWith(
          fontSize: tokens.groupTitleFontSize,
          letterSpacing: tokens.groupTitleLetterSpacing,
        ) ??
        TextStyle(
          fontSize: tokens.groupTitleFontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: tokens.groupTitleLetterSpacing,
          color: colorScheme.onSurface,
        );

    final TextStyle? subtitleTextStyle = subtitle == null
        ? null
        : theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          );

    return TilawaSectionHeader(
      title: title,
      subtitle: subtitle,
      leadingIcon: leadingIcon,
      trailing: trailing,
      padding: tokens.groupHeaderPadding,
      titleTextStyle: titleTextStyle,
      subtitleTextStyle: subtitleTextStyle,
      bottom: bottom,
    );
  }

  final String title;
  final IconData? leadingIcon;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final TextStyle titleTextStyle;
  final TextStyle? subtitleTextStyle;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: padding,
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
                        children: [
                          if (leadingIcon != null) ...[
                            Icon(
                              leadingIcon,
                              size: tokens.iconSizeSmall,
                              color: colorScheme.onSurface,
                            ),
                            SizedBox(width: tokens.spaceSmall),
                          ],
                          Flexible(
                            child: Text(
                              title,
                              style: titleTextStyle,
                              textAlign: TextAlign.start,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (subtitle != null && subtitleTextStyle != null) ...[
                      SizedBox(
                        height: Theme.of(context).tokens.spaceExtraSmall,
                      ),
                      Text(
                        subtitle!,
                        style: subtitleTextStyle!,
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
