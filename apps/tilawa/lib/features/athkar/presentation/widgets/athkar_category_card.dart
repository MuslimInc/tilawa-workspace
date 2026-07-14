import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../athkar_category_presentation.dart';

class AthkarCategoryCard extends StatelessWidget {
  const AthkarCategoryCard({
    super.key,
    required this.name,
    required this.icon,
    required this.onTap,
  });
  final String name;
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final product = theme.productColors;

    final IconData iconData = athkarCategoryIcon(icon);
    final Color accent = athkarCategoryAccent(
      icon,
      product: product,
      colorScheme: colorScheme,
    );
    final Color wash = athkarCategorySurfaceWash(
      accent: accent,
      colorScheme: colorScheme,
    );

    return TilawaCard(
      onTap: onTap,
      borderRadius: tokens.radiusExtraLarge,
      surface: TilawaCardSurface.raised,
      backgroundColor: wash,
      // Accent-tinted press ink so pastel cards still feel tappable.
      // ignore: deprecated_member_use
      splashColor: accent,
      padding: EdgeInsets.all(tokens.spaceLarge),
      // Whole card is one navigation target; let [TilawaCard.onTap] receive taps
      // from decorative children (icon box, label).
      child: IgnorePointer(
        child: Column(
          spacing: tokens.spaceMedium,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: TilawaIconBox(
                icon: iconData,
                size: tokens.iconSizeLargePlus,
                backgroundColor: accent.withValues(
                  alpha: kAthkarCategoryIconWellTintAlpha,
                ),
                iconColor: accent,
                borderRadius: tokens.radiusLarge,
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
