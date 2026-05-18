import 'package:flutter/material.dart';

import '../foundation/foundation.dart';

/// Section title row. Two flavors:
///   • `loud` — 17px bold title with an optional right-aligned action.
///   • `quiet` — uppercase 11px tracked label, used to group settings.
class TilawaSectionHeader extends StatelessWidget {
  const TilawaSectionHeader({
    required this.title,
    this.actionLabel,
    this.onActionPressed,
    this.quiet = false,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final theme = TilawaTheme.of(context);
    final c = theme.tokens.colors;

    if (quiet) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          TilawaSpacing.padX,
          18,
          TilawaSpacing.padX,
          6,
        ),
        child: Text(
          title.toUpperCase(),
          style: theme.typography.overlineMobile,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TilawaSpacing.padX,
        TilawaSpacing.padSectionY,
        TilawaSpacing.padX,
        10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.typography.h2Mobile.copyWith(color: c.fg1),
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onActionPressed,
              behavior: HitTestBehavior.opaque,
              child: Text(
                actionLabel!,
                style: theme.typography.captionMobile.copyWith(
                  color: c.brand,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
