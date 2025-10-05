// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'مزكري';

  @override
  String get reciters => 'القراء';

  @override
  String get searchReciters => 'البحث عن القراء...';

  @override
  String get loadingReciters => 'جاري تحميل القراء...';

  @override
  String get noRecitersFound => 'لم يتم العثور على قراء';

  @override
  String get noRecitersMatchSearch => 'لا يوجد قراء يطابقون البحث';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get error => 'خطأ';

  @override
  String get filteredByLetter => 'مفلتر بالحرف:';

  @override
  String get selectRecitation => 'اختر الرواية';

  @override
  String get loadingSurahList => 'جاري تحميل قائمة السور...';

  @override
  String get noSurahsAvailable => 'لا توجد سور متاحة';

  @override
  String get play => 'تشغيل';

  @override
  String get pause => 'إيقاف';

  @override
  String get next => 'التالي';

  @override
  String get previous => 'السابق';

  @override
  String get currentPlaying => 'جاري التشغيل';

  @override
  String get duration => 'المدة';

  @override
  String get position => 'الموضع';
}
