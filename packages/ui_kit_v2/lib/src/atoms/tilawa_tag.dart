import 'package:flutter/material.dart';

import '../foundation/foundation.dart';

enum TilawaTagVariant {
  gold,
  quiet, // green-tinted
  ghost, // transparent + hairline
}

/// Small pill tag. Mirrors `.tw-tag` — 22px tall, 9px horizontal padding,
/// uppercase 10px label.
class TilawaTag extends StatelessWidget {
  const TilawaTag({
    required this.label,
    this.variant = TilawaTagVariant.gold,
    this.leadingIcon,
    super.key,
  });

  final String label;
  final TilawaTagVariant variant;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final c = TilawaTheme.of(context).tokens.colors;

    final (bg, fg, border) = switch (variant) {
      TilawaTagVariant.gold => (
        TilawaPalette.gold100,
        TilawaPalette.gold700,
        null,
      ),
      TilawaTagVariant.quiet => (
        c.brandSoft,
        TilawaPalette.green700,
        null,
      ),
      TilawaTagVariant.ghost => (
        Colors.transparent,
        c.fg2,
        Border.all(color: c.hairline),
      ),
    };

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: TilawaRadii.brPill,
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: TilawaFontFamily.ui,
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
