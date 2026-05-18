import 'package:flutter/material.dart';

import '../foundation/foundation.dart';

/// Single stat tile. Used in groups of 3 on the Profile screen.
/// Mirrors `.tw-statcard`.
class TilawaStatCard extends StatelessWidget {
  const TilawaStatCard({
    required this.value,
    required this.label,
    this.unit,
    super.key,
  });

  final String value;
  final String label;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final theme = TilawaTheme.of(context);
    final c = theme.tokens.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: TilawaRadii.brMd,
        border: Border.all(color: c.hairline),
        boxShadow: TilawaShadows.el1,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: value,
              style: TextStyle(
                fontFamily: TilawaFontFamily.ui,
                fontSize: 22,
                height: 1,
                fontWeight: FontWeight.w700,
                color: TilawaPalette.green700,
                letterSpacing: -0.44,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              children: [
                if (unit != null)
                  TextSpan(
                    text: unit,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.fg2,
                      letterSpacing: 0,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: theme.typography.overlineMobile.copyWith(
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// 3-up stat row. Use sized to row width.
class TilawaStatGroup extends StatelessWidget {
  const TilawaStatGroup({required this.items, super.key});

  final List<TilawaStatCard> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TilawaSpacing.padX),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: items[i]),
          ],
        ],
      ),
    );
  }
}
