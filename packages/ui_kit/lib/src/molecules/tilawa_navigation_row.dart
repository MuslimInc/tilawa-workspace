import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../atoms/tilawa_icon_box.dart';
import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import '../foundation/semantic_tints.dart';
import 'tilawa_settings_group_row_style.dart';

/// Drill-down row for feature hub screens.
///
/// Combines a tinted [TilawaIconBox], title, supporting subtitle, and chevron.
/// Use inside [TilawaHubNavigationGroup] — not for settings toggles or switches.
///
/// **Worship-context rule:** do not use on Quran reader, prayer times, or athkar.
class TilawaNavigationRow extends StatelessWidget {
  const TilawaNavigationRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.semanticTint = TilawaSemanticTint.ink,
    this.showDivider = true,
    this.borderRadius = BorderRadius.zero,
  });

  final IconData icon;
  final String title;

  /// Supporting copy that explains the destination before the user taps.
  final String subtitle;
  final VoidCallback onTap;

  /// Manuscript tint behind the leading icon.
  final TilawaSemanticTint semanticTint;
  final bool showDivider;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.componentTokens.settingsGroup;
    final designTokens = theme.tokens;
    final BorderRadius resolvedRadius = _resolveBorderRadius(context);
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
            ),
            child: ListTile(
              minTileHeight: designTokens.minInteractiveDimension,
              contentPadding: listTileContentPadding,
              shape: RoundedRectangleBorder(borderRadius: resolvedRadius),
              leading: TilawaIconBox(
                icon: icon,
                size: tokens.tileIconSize,
                padding: resolvedIconPadding.top,
                variant: TilawaIconBoxVariant.tinted,
                semanticTint: semanticTint,
              ),
              title: _NavigationRowLabel(
                title: title,
                subtitle: subtitle,
                tokens: tokens,
              ),
              trailing: Icon(
                FluentIcons.chevron_right_20_regular,
                size: tokens.tileTrailingSize,
                color: colorScheme.onSurfaceVariant.withValues(
                  alpha: tokens.tileTrailingOpacity,
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

  BorderRadius _resolveBorderRadius(BuildContext context) {
    if (borderRadius != BorderRadius.zero) {
      return borderRadius.resolve(Directionality.of(context));
    }
    return TilawaSettingsGroupRowStyle.maybeOf(context)?.borderRadius ??
        BorderRadius.zero;
  }
}

class _NavigationRowLabel extends StatelessWidget {
  const _NavigationRowLabel({
    required this.title,
    required this.subtitle,
    required this.tokens,
  });

  final String title;
  final String subtitle;
  final TilawaSettingsGroupTokens tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.tileSubtitleSpacing,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.start,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: tokens.tileTitleFontSize,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
            height: 1.2,
          ),
        ),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.start,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: tokens.tileSubtitleFontSize,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurfaceVariant.withValues(
              alpha: tokens.tileSubtitleOpacity,
            ),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
