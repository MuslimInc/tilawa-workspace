import 'package:flutter/material.dart';
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

    return TilawaInteractiveSurface(
      onTap: onTap,
      onLongPress: onLongPress,
      semanticLabel: semanticLabel ?? title,
      stateLayerColor: cardTokens.splashColor,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: tokens.minInteractiveDimension,
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: tokens.spaceMedium,
            vertical: tokens.spaceSmall + tokens.spaceExtraSmall,
          ),
          child: Row(
            spacing: tokens.spaceMedium,
            children: [
              TilawaIconBox(
                icon: icon,
                size: tokens.iconSizeMedium,
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
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.9,
                          ),
                          height: 1.35,
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
                      size: tokens.iconSizeSmall,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: tokens.opacitySubtle * 3,
                      ),
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
