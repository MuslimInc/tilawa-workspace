// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'quran_image_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class QuranImageLocalizationsEn extends QuranImageLocalizations {
  QuranImageLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get preparingQuran => 'Preparing the Quran for you…';

  @override
  String get quranReady => 'The Quran is ready.';

  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';

  @override
  String get networkError =>
      'Please check your internet connection and try again.';

  @override
  String get appTitle => 'AlQuran';

  @override
  String get retry => 'Retry';

  @override
  String get surahIndex => 'Surah index';

  @override
  String juz(int number) {
    return 'Juz $number';
  }

  @override
  String hizb(int number) {
    return 'Hizb $number';
  }

  @override
  String page(String number) {
    return 'Page $number';
  }

  @override
  String pageIndicator(String current, String total) {
    return 'Page $current of $total';
  }
}
