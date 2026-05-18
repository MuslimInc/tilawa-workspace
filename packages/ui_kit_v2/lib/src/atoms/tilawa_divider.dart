import 'package:flutter/material.dart';

import '../foundation/foundation.dart';

enum TilawaDividerInset {
  /// Default — inset by `--pad-x` (20) on both sides.
  edge,

  /// Inset on the leading side so it aligns with row text after an icon
  /// (`--pad-x + 52` in the CSS).
  trailingFromIcon,

  /// Flush, no horizontal inset.
  flush,
}

/// Hairline divider matching `.tw-divider`. Honours design-system inset rules.
class TilawaDivider extends StatelessWidget {
  const TilawaDivider({
    this.inset = TilawaDividerInset.edge,
    super.key,
  });

  final TilawaDividerInset inset;

  @override
  Widget build(BuildContext context) {
    final c = TilawaTheme.of(context).tokens.colors;
    final padding = switch (inset) {
      TilawaDividerInset.edge => const EdgeInsets.symmetric(
        horizontal: TilawaSpacing.padX,
      ),
      TilawaDividerInset.trailingFromIcon => const EdgeInsets.only(
        left: TilawaSpacing.padX + 52,
      ),
      TilawaDividerInset.flush => EdgeInsets.zero,
    };
    return Padding(
      padding: padding,
      child: Container(height: 1, color: c.hairline),
    );
  }
}
