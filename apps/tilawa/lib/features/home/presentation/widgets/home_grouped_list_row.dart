import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_section.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Compact navigation row for grouped Home cards (More, pinned athkar).
class HomeGroupedListRow extends StatelessWidget {
  const HomeGroupedListRow({
    super.key,
    required this.icon,
    this.iconTint = TilawaSemanticTint.ink,
    this.iconBackgroundColor,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.onLongPress,
    this.showChevron = true,
    this.semanticLabel,
    this.trailingWidget,
  });

  final IconData icon;

  /// Semantic tint for the leading icon box. Used when [iconBackgroundColor]
  /// and [iconColor] are not provided.
  final TilawaSemanticTint iconTint;

  /// Explicit icon box background color — overrides [iconTint] when set.
  final Color? iconBackgroundColor;

  /// Explicit icon glyph color — overrides [iconTint] when set.
  final Color? iconColor;

  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool showChevron;
  final String? semanticLabel;

  /// Optional widget appended after the title column, replacing the chevron
  /// when provided (e.g. a [TilawaExperimentalBadge]).
  final Widget? trailingWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final cardTokens = theme.componentTokens.homeDashboardCard;
    final bool isArabic = context.isArabic;
    final double titleHeight = isArabic ? 1.35 : 1.25;
    final double subtitleHeight = isArabic ? 1.5 : 1.4;

    return TilawaInteractiveSurface(
      onTap: onTap,
      onLongPress: onLongPress,
      semanticLabel: semanticLabel ?? title,
      stateLayerColor: cardTokens.splashColor,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // Comfortable phone row (~88dp) without competing with primary tiles.
          minHeight: tokens.minInteractiveDimension * 2,
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: tokens.spaceMedium,
            vertical: tokens.spaceMedium,
          ),
          child: Row(
            spacing: tokens.spaceMedium,
            children: [
              TilawaIconBox(
                icon: icon,
                size: tokens.iconSizeLarge,
                variant: TilawaIconBoxVariant.tinted,
                semanticTint: iconTint,
                backgroundColor: iconBackgroundColor,
                iconColor: iconColor,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: tokens.spaceExtraSmall,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        height: titleHeight,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: subtitleHeight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailingWidget != null)
                trailingWidget!
              else if (showChevron)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.55,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(tokens.spaceExtraSmall * 0.5),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: tokens.iconSizeMedium,
                      color: HomeDashboardSection.secondaryTextColor(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
