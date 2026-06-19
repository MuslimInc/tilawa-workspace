import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Compact navigation row for grouped Home cards (More, pinned athkar).
class HomeGroupedListRow extends StatelessWidget {
  const HomeGroupedListRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.onLongPress,
    this.showChevron = true,
    this.semanticLabel,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool showChevron;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final cardTokens = theme.componentTokens.homeDashboardCard;

    return Semantics(
      button: true,
      label: semanticLabel ?? title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          splashColor: cardTokens.splashColor,
          highlightColor: cardTokens.highlightColor,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: tokens.minInteractiveDimension,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceMedium,
                vertical: tokens.spaceSmall,
              ),
              child: Row(
                spacing: tokens.spaceMedium,
                children: [
                  TilawaIconBox(
                    icon: icon,
                    size: tokens.iconSizeMedium,
                    variant: TilawaIconBoxVariant.tinted,
                    semanticTint: TilawaSemanticTint.ink,
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
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (showChevron)
                    // Keep the right chevron in both LTR and RTL; this icon
                    // reads correctly in Arabic and avoids unwanted mirroring.
                    Icon(
                      Icons.chevron_right_rounded,
                      size: tokens.iconSizeSmall,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
