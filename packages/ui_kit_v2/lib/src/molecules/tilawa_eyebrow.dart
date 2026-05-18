import 'package:flutter/material.dart';

import '../foundation/foundation.dart';

/// Small uppercase tracked label rendered above a hero title or section.
/// Mirrors `.tw-eyebrow`.
class TilawaEyebrow extends StatelessWidget {
  const TilawaEyebrow(this.text, {this.color, super.key});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = TilawaTheme.of(context);
    final style = theme.typography.eyebrow.copyWith(
      color: color ?? theme.tokens.colors.brand,
    );
    return Text(text.toUpperCase(), style: style);
  }
}
