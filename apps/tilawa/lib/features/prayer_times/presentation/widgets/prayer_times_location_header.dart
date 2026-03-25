import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tilawa/core/extensions.dart';
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.today,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dayName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fullDate,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LocationRow(
            locationName: locationName,
            isLoading: isLoading,
            onUpdateLocation: onUpdateLocation,
          ),
        ],
      ),
    );
  }
}
