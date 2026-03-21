import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tilawa/features/prayer_times/presentation/widgets/location_row.dart';

class PrayerTimesLocationHeader extends StatelessWidget {
  const PrayerTimesLocationHeader({
    super.key,
    required this.locationName,
    required this.isLoading,
    required this.onUpdateLocation,
  });

  final String? locationName;
  final bool isLoading;
  final VoidCallback onUpdateLocation;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final now = DateTime.now();

    // Day name (e.g., الخميس / Thursday)
    final String dayName = DateFormat(
      'EEEE',
      isArabic ? 'ar' : 'en',
    ).format(now);

    // Full date formatted
    String fullDate = DateFormat.yMMMMd(isArabic ? 'ar' : 'en').format(now);

    if (isArabic) {
      const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
      const englishNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
      for (int i = 0; i < arabicNumbers.length; i++) {
        fullDate = fullDate.replaceAll(arabicNumbers[i], englishNumbers[i]);
      }
    }

    // Prefix text
    final String prefixText = isArabic
        ? 'مواقيت الصلاة ليوم $dayName'
        : 'Prayer times for $dayName';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location Row Container (Molecular Component)
          LocationRow(
            locationName: locationName,
            isLoading: isLoading,
            onUpdateLocation: onUpdateLocation,
          ),

          SizedBox(height: 12),

          // Date Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                prefixText,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                fullDate,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
