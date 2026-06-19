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

    final IconData iconData = athkarCategoryIcon(icon);

    return TilawaCard(
      onTap: onTap,
      borderRadius: tokens.radiusExtraLarge,
      surface: TilawaCardSurface.raised,
      backgroundColor: colorScheme.surface,
      padding: EdgeInsets.all(tokens.spaceLarge),
      // Whole card is one navigation target; let [TilawaCard.onTap] receive taps
      // from decorative children (icon box, label).
      child: IgnorePointer(
        child: Column(
          spacing: tokens.spaceMedium,
          crossAxisAlignment: .stretch,
          mainAxisSize: .min,
          children: [
            Expanded(
              child: TilawaIconBox(
                icon: iconData,
                size: tokens.iconSizeLarge,
                backgroundColor: colorScheme.primary.withValues(
                  alpha: tokens.opacitySubtle,
                ),
                iconColor: colorScheme.primary,
                borderRadius: tokens.radiusLarge,
              ),
            ),
            Flexible(
              child: Align(
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
            ),
          ],
        ),
      ),
    );
  }
}
