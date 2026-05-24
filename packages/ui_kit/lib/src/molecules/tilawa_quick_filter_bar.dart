import 'package:flutter/material.dart';

import '../foundation/design_tokens.dart';

/// Horizontal strip of catalog filter pills (Booking / Noon pattern).
///
/// Place directly under a [TilawaSearchField]. [children] are usually
/// [TilawaSelectionPill] widgets. Optional [trailing] hosts actions such as
/// "Clear all" or an overflow menu.
class TilawaQuickFilterBar extends StatelessWidget {
  const TilawaQuickFilterBar({
    super.key,
    required this.children,
    this.trailing,
    this.padding,
  });

  final List<Widget> children;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final TilawaDesignTokens tokens = Theme.of(context).tokens;

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: tokens.spaceSmall,
                children: children,
              ),
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: tokens.spaceSmall),
            trailing!,
          ],
        ],
      ),
    );
  }
}
