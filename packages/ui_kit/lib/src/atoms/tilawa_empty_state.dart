import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';

/// A generic, feature-agnostic empty-state widget.
///
/// Shows a centered column with an icon, title, optional subtitle,
/// and optional action widget. Uses design tokens for spacing and
/// sizing. Does not include any business-specific copy.
class TilawaEmptyState extends StatelessWidget {
  /// Creates an empty-state placeholder.
  const TilawaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconColor,
  });

  /// The icon shown above the title.
  final IconData icon;

  /// Primary message displayed below the icon.
  final String title;

  /// Optional secondary description below the title.
  final String? subtitle;

  /// Optional action widget (e.g. a button) below the subtitle.
  final Widget? action;

  /// Override color for the icon. Defaults to
  /// `colorScheme.onSurface` with token-driven opacity.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.emptyState;

    return Center(
      child: Padding(
        padding: tokens.padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: tokens.iconSize,
              color:
                  iconColor ??
                  theme.colorScheme.onSurface.withValues(
                    alpha: tokens.iconOpacity,
                  ),
            ),
            SizedBox(height: tokens.titleSpacing),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: tokens.subtitleSpacing),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              SizedBox(height: tokens.actionSpacing),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
