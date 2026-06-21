import 'package:flutter/widgets.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';

/// Provides easy access to Quran Sessions package-local localization.
extension QuranSessionsL10nX on BuildContext {
  QuranSessionsLocalizations get quranSessionsL10n =>
      QuranSessionsLocalizations.of(this);
}
