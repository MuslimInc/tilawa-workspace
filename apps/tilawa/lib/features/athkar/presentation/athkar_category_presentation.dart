import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';

import '../domain/entities/athkar_category.dart';

String localizedAthkarCategoryTitle(
  BuildContext context,
  AthkarCategory category,
) {
  if (context.isArabic) return category.nameAr;
  final String english = category.nameEn.trim();
  return english.isNotEmpty ? english : category.nameAr;
}

IconData athkarCategoryIcon(String iconName) {
  switch (iconName) {
    case 'wb_sunny_rounded':
      return Icons.wb_sunny_rounded;
    case 'nights_stay_rounded':
      return Icons.nights_stay_rounded;
    case 'bedtime_rounded':
      return Icons.bedtime_rounded;
    case 'alarm_rounded':
      return Icons.alarm_rounded;
    case 'mosque_rounded':
      return Icons.mosque_rounded;
    case 'auto_stories_rounded':
      return Icons.auto_stories_rounded;
    case 'prayer_times_rounded':
      return Icons.auto_awesome_rounded;
    case 'tasbeeh':
      return Icons.radio_button_checked_rounded;
    default:
      return Icons.bookmark_added_rounded;
  }
}
