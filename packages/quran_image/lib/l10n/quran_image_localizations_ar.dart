// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'quran_image_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class QuranImageLocalizationsAr extends QuranImageLocalizations {
  QuranImageLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get preparingQuran => 'جارٍ تجهيز القرآن لك…';

  @override
  String get quranReady => 'القرآن جاهز.';

  @override
  String get somethingWentWrong => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get networkError =>
      'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';

  @override
  String get appTitle => 'القرآن';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get surahIndex => 'فهرس السور';

  @override
  String juz(int number) {
    return 'الجزء $number';
  }

  @override
  String hizb(int number) {
    return 'الحزب $number';
  }

  @override
  String page(String number) {
    return 'صفحة $number';
  }

  @override
  String pageIndicator(String current, String total) {
    return 'صفحة $current من $total';
  }
}
