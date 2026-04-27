import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

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
        mainAxisAlignment: .center,
        spacing: tokens.spaceMedium,
        children: [
          TilawaIconBox(
            icon: getIcon(icon),
            size: tokens.iconSizeLarge,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            iconColor: colorScheme.primary,
            borderRadius: tokens.radiusMedium,
          ),
          Text(
            name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
