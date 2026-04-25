import 'package:flutter/material.dart';
import 'package:tilawa/l10n/generated/app_localizations_ar.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../l10n/generated/app_localizations.dart';

extension AppLang on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      AppLocalizationsAr();
}

extension BuildContextThemeX on BuildContext {
  bool get isDarkMode => theme.brightness == Brightness.dark;
}
