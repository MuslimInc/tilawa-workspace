import 'package:flutter/widgets.dart';

import '../../../../core/utils/surah_names.dart';
import '../../domain/entities/download_item.dart';

extension DownloadItemExtensions on DownloadItem {
  /// localized surah name
  String getLocalizedSurahName(BuildContext context) {
    final String languageCode = Localizations.localeOf(context).languageCode;
    String surahName = title;
    int? surahId = int.tryParse(url);

    if (surahId == null) {
      try {
        // Handle cases where url is a full URL ending in "001.mp3"
        final Uri uri = Uri.parse(url);
        final String basename = uri.pathSegments.last;
        final String name = basename.split('.').first;
        surahId = int.tryParse(name);
      } catch (_) {
        // Ignore parsing errors
      }
    }

    if (surahId != null) {
      if (languageCode == 'en') {
        surahName = SurahNames.getEnglishSurahName(surahId);
      } else {
        surahName = SurahNames.getArabicSurahName(surahId);
      }
    }
    return surahName;
  }
}
