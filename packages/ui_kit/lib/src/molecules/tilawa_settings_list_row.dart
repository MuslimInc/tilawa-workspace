import 'package:flutter/material.dart';

import '../foundation/tilawa_interactive_surface.dart';

/// Shared tappable row chrome for settings and hub navigation lists.
///
/// Routes through [TilawaInteractiveSurface] so list rows share the kit press
/// scale, focus ring, and haptics instead of Material [ListTile] ink.
class TilawaSettingsListRow extends StatelessWidget {
  const TilawaSettingsListRow({
    super.key,
    required this.semanticLabel,
    required this.borderRadius,
    required this.contentPadding,
    required this.minTileHeight,
    required this.rowGap,
    required this.title,
    this.leading,
    this.trailing,
    this.onTap,
    this.semanticsIdentifier,
    this.toggled,
    this.selected,
  });

  final String semanticLabel;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry contentPadding;
  final double minTileHeight;
  final double rowGap;
  final Widget title;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticsIdentifier;
  final bool? toggled;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final Widget row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minTileHeight),
      child: Padding(
        padding: contentPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              SizedBox(width: rowGap),
            ],
            Expanded(child: title),
            ?trailing,
          ],
        ),
      ),
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: TilawaInteractiveSurface(
        onTap: onTap,
        borderRadius: borderRadius,
        semanticLabel: semanticLabel,
        semanticsIdentifier: semanticsIdentifier,
        toggled: toggled,
        selected: selected,
        child: row,
      ),
    );
  }
}
