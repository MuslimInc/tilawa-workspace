import 'package:flutter/material.dart';

import '../atoms/atoms.dart';
import '../foundation/foundation.dart';

/// Player-screen header. Back button (left), centered eyebrow + reciter name,
/// kebab/options menu (right). Mirrors `.tw-player-header`.
class TilawaPlayerHeader extends StatelessWidget {
  const TilawaPlayerHeader({
    required this.eyebrow,
    required this.title,
    required this.onBack,
    this.onMore,
    super.key,
  });

  final String eyebrow;
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final theme = TilawaTheme.of(context);
    final c = theme.tokens.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TilawaSpacing.padX,
        TilawaSpacing.s16,
        TilawaSpacing.padX,
        12,
      ),
      child: Row(
        children: [
          TilawaIconBtn(
            icon: Icons.arrow_back_ios_new,
            onPressed: onBack,
            semanticLabel: 'Back',
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: theme.typography.eyebrow,
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: TilawaFontFamily.ui,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.fg1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TilawaIconBtn(
            icon: Icons.more_horiz,
            onPressed: onMore,
            semanticLabel: 'More options',
          ),
        ],
      ),
    );
  }
}
