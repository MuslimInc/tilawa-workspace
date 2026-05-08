import 'package:flutter/material.dart';
import 'package:tilawa/features/prayer_times/presentation/widgets/location_row.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class PrayerTimesLocationHeader extends StatelessWidget {
  const PrayerTimesLocationHeader({
    super.key,
    required this.locationName,
    required this.isLoading,
    required this.onUpdateLocation,
    this.onOpenQibla,
  });

  final String? locationName;
  final bool isLoading;
  final VoidCallback onUpdateLocation;
  final VoidCallback? onOpenQibla;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        tokens.spaceExtraSmall,
        tokens.spaceLarge,
        0,
      ),
      child: LocationRow(
        locationName: locationName,
        isLoading: isLoading,
        onUpdateLocation: onUpdateLocation,
        onOpenQibla: onOpenQibla,
      ),
    );
  }
}
