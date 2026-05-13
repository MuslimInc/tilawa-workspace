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
    Widget? trailing,
    Widget? bottom,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.componentTokens.settingsGroup;

    final TextStyle? base = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      height: 1.25,
      color: colorScheme.onSurface,
    );

    final TextStyle titleTextStyle =
        base?.copyWith(
          fontSize: tokens.groupTitleFontSize,
          letterSpacing: tokens.groupTitleLetterSpacing,
        ) ??
        TextStyle(
          fontSize: tokens.groupTitleFontSize,
          fontWeight: FontWeight.w700,
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
      trailing: trailing,
      padding: tokens.groupHeaderPadding,
      titleTextStyle: titleTextStyle,
      subtitleTextStyle: subtitleTextStyle,
      bottom: bottom,
    );
  }

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final TextStyle titleTextStyle;
  final TextStyle? subtitleTextStyle;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
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
                      child: Text(
                        title,
                        style: titleTextStyle,
                        textAlign: TextAlign.start,
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
