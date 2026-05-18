import 'package:flutter/material.dart';

import '../foundation/foundation.dart';

/// Empty / zero-data state. Soft brand-tinted icon → title → body → CTA.
/// Mirrors `.tw-empty`.
class TilawaEmptyState extends StatelessWidget {
  const TilawaEmptyState({
    required this.icon,
    required this.title,
    this.body,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = TilawaTheme.of(context);
    final c = theme.tokens.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0x142D5C3F),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: TilawaPalette.green700),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: TilawaFontFamily.ui,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: c.fg1,
            ),
          ),
          if ((body ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Text(
                body!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: TilawaFontFamily.ui,
                  fontSize: 13,
                  height: 1.6,
                  color: c.fg2,
                ),
              ),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}
