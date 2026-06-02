import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';

class TilawaSectionTitle extends StatelessWidget {
  const TilawaSectionTitle({
    super.key,
    required this.title,
    this.color,
    this.fontWeight,
  }) : _isOverline = false;

  /// Overline variant: small uppercase tracked label used above a section.
  ///
  /// Matches the Noon / Amazon pattern of a muted CATEGORY LABEL sitting
  /// above the section's main heading or card group.
  const TilawaSectionTitle.overline({
    super.key,
    required this.title,
    this.color,
    this.fontWeight,
  }) : _isOverline = true;

  final String title;
  final Color? color;
  final FontWeight? fontWeight;
  final bool _isOverline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final componentTokens = theme.componentTokens.sectionTitle;

    if (_isOverline) {
      return Semantics(
        header: true,
        child: Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: color ?? colorScheme.onSurfaceVariant,
            fontWeight: fontWeight ?? FontWeight.w700,
            letterSpacing: 1.2,
            height: 1.2,
          ),
        ),
      );
    }

    return Semantics(
      header: true,
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: color,
          fontWeight: fontWeight ?? componentTokens.fontWeight,
        ),
      ),
    );
  }
}
