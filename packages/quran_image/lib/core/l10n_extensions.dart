import 'package:flutter/widgets.dart';
import 'package:quran_image/l10n/quran_image_localizations.dart';

/// Provides easy access to Quran Image package-local localization.
extension QuranImageL10nX on BuildContext {
  QuranImageLocalizations get quranImageL10n =>
      QuranImageLocalizations.of(this);
}
