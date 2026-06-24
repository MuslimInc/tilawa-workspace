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
    this.scrollPadding,
  });

  final List<Widget> children;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  /// Inset around the horizontally scrollable pill row (e.g. trailing edge
  /// breathing room when chips overflow).
  final EdgeInsetsGeometry? scrollPadding;

  @override
  Widget build(BuildContext context) {
    final TilawaDesignTokens tokens = Theme.of(context).tokens;

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Semantics(
              // Let each pill keep its own button semantics while the strip
              // remains a scrollable region (user control / a11y).
              explicitChildNodes: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    scrollPadding ??
                    EdgeInsetsDirectional.only(end: tokens.spaceSmall),
                child: Row(
                  spacing: tokens.spaceSmall,
                  children: children,
                ),
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
