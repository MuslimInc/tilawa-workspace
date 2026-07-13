import 'package:flutter/material.dart';

import '../atoms/tilawa_icon_box.dart';
import '../foundation/component_tokens.dart';
import '../foundation/tilawa_icons.dart';
import '../foundation/design_tokens.dart';
import '../foundation/semantic_tints.dart';
import '../foundation/tilawa_text_roles.dart';
import 'tilawa_settings_group_row_style.dart';
import 'tilawa_settings_list_row.dart';

/// Visual weight for [TilawaNavigationRow] inside hub navigation groups.
enum TilawaNavigationRowEmphasis {
  /// Primary hub action — tinted icon and strongest title weight.
  primary,

  /// Standard navigation row.
  secondary,

  /// Low-emphasis action — outline icon and quieter title colour.
  tertiary,
}

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
    this.emphasis = TilawaNavigationRowEmphasis.secondary,
    this.semanticTint = TilawaSemanticTint.ink,
    this.showDivider = true,
    this.borderRadius = BorderRadius.zero,
    this.showsNavigationChevron = true,
  });

  final IconData icon;
  final String title;

  /// Supporting copy that explains the destination before the user taps.
  final String subtitle;
  final VoidCallback onTap;
  final TilawaNavigationRowEmphasis emphasis;

  /// Manuscript tint behind the leading icon.
  final TilawaSemanticTint semanticTint;
  final bool showDivider;
  final BorderRadiusGeometry borderRadius;

  /// When false, omits the trailing chevron for in-place actions such as
  /// confirmation dialogs.
  final bool showsNavigationChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.componentTokens.settingsGroup;
    final designTokens = theme.tokens;
    final BorderRadius resolvedRadius = _resolveBorderRadius(context);
    final TextDirection direction = Directionality.of(context);
    final EdgeInsets resolvedIconPadding = tokens.tileIconPadding.resolve(
      direction,
    );
    final _NavigationRowVisualStyle visualStyle = _NavigationRowVisualStyle(
      emphasis: emphasis,
      colorScheme: colorScheme,
      tokens: tokens,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TilawaSettingsListRow(
          semanticLabel: '$title. $subtitle',
          borderRadius: resolvedRadius,
          contentPadding: EdgeInsetsDirectional.only(
            start: designTokens.spaceSmall,
            end: designTokens.spaceSmall,
            top: designTokens.spaceLarge,
            bottom: designTokens.spaceLarge,
          ),
          minTileHeight: designTokens.minInteractiveDimension,
          rowGap: tokens.tileItemGap,
          crossAxisAlignment: CrossAxisAlignment.center,
          onTap: onTap,
          leading: TilawaIconBox(
            icon: icon,
            size: tokens.tileIconSize,
            padding: resolvedIconPadding.top,
            variant: visualStyle.iconVariant,
            semanticTint: semanticTint,
          ),
          title: _NavigationRowLabel(
            title: title,
            subtitle: subtitle,
            tokens: tokens,
            designTokens: designTokens,
            titleColor: visualStyle.titleColor,
            titleWeight: visualStyle.titleWeight,
          ),
          trailing: showsNavigationChevron
              ? Icon(
                  TilawaIcons.chevronRightSmall,
                  size: tokens.tileTrailingSize,
                  color: colorScheme.onSurfaceVariant.withValues(
                    alpha: tokens.tileTrailingOpacity,
                  ),
                )
              : null,
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

@immutable
class _NavigationRowVisualStyle {
  const _NavigationRowVisualStyle({
    required this.emphasis,
    required this.colorScheme,
    required this.tokens,
  });

  final TilawaNavigationRowEmphasis emphasis;
  final ColorScheme colorScheme;
  final TilawaSettingsGroupTokens tokens;

  TilawaIconBoxVariant get iconVariant => switch (emphasis) {
    TilawaNavigationRowEmphasis.primary ||
    TilawaNavigationRowEmphasis.secondary => TilawaIconBoxVariant.tinted,
    TilawaNavigationRowEmphasis.tertiary => TilawaIconBoxVariant.outline,
  };

  Color get titleColor => switch (emphasis) {
    TilawaNavigationRowEmphasis.primary ||
    TilawaNavigationRowEmphasis.secondary => colorScheme.onSurface,
    TilawaNavigationRowEmphasis.tertiary => colorScheme.onSurfaceVariant,
  };

  FontWeight get titleWeight => switch (emphasis) {
    TilawaNavigationRowEmphasis.primary => FontWeight.w700,
    TilawaNavigationRowEmphasis.secondary ||
    TilawaNavigationRowEmphasis.tertiary => FontWeight.w600,
  };
}

class _NavigationRowLabel extends StatelessWidget {
  const _NavigationRowLabel({
    required this.title,
    required this.subtitle,
    required this.tokens,
    required this.designTokens,
    required this.titleColor,
    required this.titleWeight,
  });

  final String title;
  final String subtitle;
  final TilawaSettingsGroupTokens tokens;
  final MeMuslimDesignTokens designTokens;
  final Color titleColor;
  final FontWeight titleWeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final double subtitleOpacity = (tokens.tileSubtitleOpacity + 0.12).clamp(
      0.0,
      1.0,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: designTokens.spaceSmall,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.start,
          style:
              tilawaResolveTextRole(
                theme.textTheme,
                tokens.tileTitleTextRole,
              ).copyWith(
                fontWeight: titleWeight,
                color: titleColor,
                height: 1.2,
              ),
        ),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.start,
          style:
              tilawaResolveTextRole(
                theme.textTheme,
                TilawaTextRole.labelSmall,
              ).copyWith(
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurfaceVariant.withValues(
                  alpha: subtitleOpacity,
                ),
                height: 1.3,
              ),
        ),
      ],
    );
  }
}
