import 'package:tilawa/l10n/generated/app_localizations.dart';

/// Formats potentially verbose geocoded addresses for space-constrained UI.
abstract final class PrayerLocationLabelFormatter {
  static String abbreviatedLocationLabel({
    required String? locationName,
    required AppLocalizations l10n,
  }) {
    if (locationName == null || locationName.trim().isEmpty) {
      return l10n.unknownLocation;
    }

    final segments = locationName
        .split(RegExp(r'[,،؛]'))
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();

    if (segments.isEmpty) {
      return l10n.unknownLocation;
    }

    // Prefer broader area/city segments from the end.
    if (segments.length > 1) {
      for (final segment in segments.reversed) {
        if (!looksStreetLevel(segment)) {
          return segment;
        }
      }
      return segments.last;
    }

    return looksStreetLevel(segments.first)
        ? l10n.unknownLocation
        : segments.first;
  }

  static bool looksStreetLevel(String value) {
    final lower = value.toLowerCase();
    if (RegExp(r'\d').hasMatch(lower)) {
      return true;
    }

    const streetHints = [
      'street',
      'st',
      'road',
      'rd',
      'avenue',
      'ave',
      'lane',
      'ln',
      'boulevard',
      'blvd',
      'building',
      'block',
      'unit',
      'apt',
      'floor',
      'tower',
      'district',
      'square',
      'plaza',
      'شارع',
      'طريق',
      'حي',
      'مبنى',
      'عمارة',
      'شقة',
      'دور',
      'برج',
      'ميدان',
    ];

    for (final hint in streetHints) {
      if (lower.contains(hint)) {
        return true;
      }
    }

    return false;
  }
}
