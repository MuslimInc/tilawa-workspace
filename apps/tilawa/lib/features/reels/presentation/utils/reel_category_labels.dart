import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';

/// Resolves mp3quran video_type ids to localized category labels.
abstract final class ReelCategoryLabels {
  static Map<int, String> map(BuildContext context) {
    final l10n = context.l10n;
    return {
      2: l10n.reelsCategoryProphet,
      3: l10n.reelsCategoryFaith,
      4: l10n.reelsCategoryRamadan,
    };
  }

  static String forId(BuildContext context, int categoryId) {
    return map(context)[categoryId] ?? context.l10n.reelsCategoryUnknown;
  }

  static String apiLanguage(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar' ? 'ar' : 'eng';
  }
}
