// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get networkError =>
      'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';

  @override
  String get unexpectedError => 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get quranImage => 'صورة القرآن';

  @override
  String get loadingMarkerCoordinates => 'جاري تحميل إحداثيات العلامات...';

  @override
  String pageIndicator(String current, String total) {
    return 'صفحة $current من $total';
  }
}
