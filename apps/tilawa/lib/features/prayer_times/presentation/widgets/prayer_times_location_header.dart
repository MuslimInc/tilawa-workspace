import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/prayer_times/presentation/widgets/location_row.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

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

    final tokens = theme.tokens;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        tokens.spaceExtraSmall,
        tokens.spaceLarge,
        tokens.spaceSmall,
      ),
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
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: tokens.spaceExtraSmall),
                    Text(
                      dayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fullDate,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(tokens.radiusMedium),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spaceMedium),
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
