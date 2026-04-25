import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/athkar_category.dart';

class AthkarCategoryCard extends StatelessWidget {
  const AthkarCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });
  final AthkarCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    // Map icon string to IconData (simplified for now)
    IconData getIcon(String iconName) {
      switch (iconName) {
        case 'wb_sunny_rounded':
          return Icons.wb_sunny_rounded;
        case 'nights_stay_rounded':
          return Icons.nights_stay_rounded;
        case 'prayer_times_rounded':
          return Icons.auto_awesome_rounded;
        default:
          return Icons.bookmark_added_rounded;
      }
    }

    return TilawaCard(
      onTap: onTap,
      borderRadius: tokens.radiusExtraLarge,
      padding: EdgeInsets.all(tokens.spaceLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TilawaIconBox(
            icon: getIcon(category.icon),
            size: tokens.iconSizeLarge,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            iconColor: colorScheme.primary,
            borderRadius: tokens.radiusMedium,
          ),
          SizedBox(height: tokens.spaceMedium),
          Text(
            category.nameAr,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: tokens.spaceSmall),
          Text(
            category.nameEn,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
