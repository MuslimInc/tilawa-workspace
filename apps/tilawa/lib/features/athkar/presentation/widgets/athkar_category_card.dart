import 'package:flutter/material.dart';

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
    final ThemeData theme = Theme.of(context);
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

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    getIcon(category.icon),
                    size: 32,
                    color: theme.primaryColor,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  category.nameAr,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  category.nameEn,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
