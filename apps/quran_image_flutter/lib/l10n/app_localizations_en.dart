// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get networkError =>
      'No internet connection. Please check your network and try again.';

  @override
  String get unexpectedError =>
      'An unexpected error occurred. Please try again.';

  @override
  String get retry => 'Retry';

  @override
  String get quranImage => 'Quran Image';

  @override
  String get loadingMarkerCoordinates => 'Loading marker coordinates...';

  @override
  String pageIndicator(String current, String total) {
    return 'Page $current of $total';
  }
}
