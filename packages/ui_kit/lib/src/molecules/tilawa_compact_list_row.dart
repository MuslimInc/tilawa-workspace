import 'package:flutter/material.dart';

import '../atoms/tilawa_divider.dart';
import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

/// Dense list row with optional leading, subtitle, and trailing action.
///
/// Prefer over [ListTile] when rows should stay near
/// [TilawaDesignTokens.minInteractiveDimension] tall while still exposing a
/// 48×48 trailing control.
class TilawaCompactListRow extends StatelessWidget {
  const TilawaCompactListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleStyle,
    this.leading,
    this.trailing,
    this.showDivider = false,
  });

  final String title;
  final String? subtitle;
  final TextStyle? subtitleStyle;
  final Widget? leading;
  final Widget? trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.componentTokens.settingsGroup;
    final designTokens = theme.tokens;
    final subtitleText = subtitle;

    final titleStyle = theme.textTheme.bodyLarge?.copyWith(
      fontSize: tokens.tileTitleFontSize,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
      height: 1.15,
    );

    final effectiveSubtitleStyle =
        subtitleStyle ??
        theme.textTheme.bodySmall?.copyWith(
          fontSize: tokens.tileSubtitleFontSize,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant.withValues(
            alpha: tokens.tileSubtitleOpacity,
          ),
          height: 1.2,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: designTokens.minInteractiveDimension,
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: designTokens.spaceSmall,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  leading!,
                  SizedBox(width: tokens.tileItemGap),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: subtitleText == null
                        ? 0
                        : tokens.tileSubtitleSpacing,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                      if (subtitleText != null)
                        Text(
                          subtitleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: effectiveSubtitleStyle,
                        ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
        if (showDivider) const TilawaDivider(),
      ],
    );
  }
}
