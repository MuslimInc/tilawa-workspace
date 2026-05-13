import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';

/// A short inline banner that surfaces a missing permission or capability and
/// offers a single trailing call-to-action.
///
/// Defaults to `tertiaryContainer` styling. Pass [backgroundColor] /
/// [foregroundColor] to retheme for warning or error contexts.
///
/// All copy is the caller's responsibility — this widget intentionally has
/// no l10n or app-specific knowledge.
class TilawaPermissionBanner extends StatelessWidget {
  const TilawaPermissionBanner({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.icon = Icons.info_outline,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.componentTokens.permissionBanner;

    final Color bg = backgroundColor ?? colorScheme.tertiaryContainer;
    final Color fg = foregroundColor ?? colorScheme.onTertiaryContainer;

    return Container(
      padding: padding ?? tokens.padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(
          borderRadius ?? tokens.borderRadius,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: tokens.iconSize, color: fg),
          SizedBox(width: tokens.iconSpacing),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: fg),
            ),
          ),
          SizedBox(width: tokens.actionSpacing),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: tokens.actionSpacing),
              // fix: Accessibility — preserve Material ≥48dp minimum touch target
            ),
            child: Text(
              actionLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
