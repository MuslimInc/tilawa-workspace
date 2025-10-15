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

  @override
  String get downloads => 'التحميلات';

  @override
  String get playlists => 'قوائم التشغيل';

  @override
  String get noDownloadsYet => 'لا توجد تحميلات بعد';

  @override
  String get downloading => 'جاري التحميل';

  @override
  String get downloaded => 'تم التحميل';

  @override
  String get download => 'تحميل';

  @override
  String get delete => 'حذف';

  @override
  String get deleteAll => 'حذف الكل';

  @override
  String get clearAllDownloads => 'مسح جميع التحميلات';

  @override
  String get clearAllDownloadsMessage =>
      'هل أنت متأكد من حذف جميع السور المحملة؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get playAll => 'تشغيل الكل';

  @override
  String get pauseAll => 'إيقاف الكل';

  @override
  String get playing => 'جاري التشغيل';

  @override
  String get pending => 'في الانتظار';

  @override
  String get cancelled => 'ملغي';

  @override
  String get completed => 'مكتمل';

  @override
  String get downloadProgress => 'تقدم التحميل';

  @override
  String get fileSize => 'حجم الملف';

  @override
  String get downloadedSize => 'الحجم المحمل';

  @override
  String get playlistsScreen => 'شاشة قوائم التشغيل';

  @override
  String get back => 'رجوع';

  @override
  String get noPlaylistsYet => 'لا توجد قوائم تشغيل بعد';

  @override
  String get createPlaylist => 'إنشاء قائمة تشغيل';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get downloadStatusChecked => 'تم فحص حالة التحميل';

  @override
  String get fileValidationCompleted => 'تم التحقق من صحة الملف';

  @override
  String get validDownloadsLoaded => 'تم تحميل التحميلات الصحيحة';

  @override
  String get playbackInitiated => 'تم بدء التشغيل';

  @override
  String get error => 'خطأ';

  @override
  String get settings => 'الإعدادات';

  @override
  String get retryDownload => 'إعادة تحميل';

  @override
  String get retryDownloadTooltip => 'إعادة تحميل';

  @override
  String get viewDownloads => 'عرض التحميلات';

  @override
  String get premium => 'بريميوم';

  @override
  String get premiumFeatures => 'ميزات بريميوم';

  @override
  String get unlimitedDownloads => 'تحميلات غير محدودة';

  @override
  String get offlineMode => 'الوضع غير المتصل';

  @override
  String get highQualityAudio => 'صوت عالي الجودة';

  @override
  String get adFreeExperience => 'تجربة خالية من الإعلانات';

  @override
  String get prioritySupport => 'دعم ذو أولوية';

  @override
  String get exclusiveContent => 'محتوى حصري';

  @override
  String get chooseYourPlan => 'اختر خطتك';

  @override
  String get maybeLater => 'ربما لاحقاً';

  @override
  String get upgradeNow => 'ترقية الآن';

  @override
  String get continueButton => 'متابعة';

  @override
  String get premiumRequired => 'بريميوم مطلوب';

  @override
  String get premiumRequiredMessage =>
      'هذه الميزة تتطلب اشتراك بريميوم. قم بالترقية لفتح التحميلات غير المحدودة والمزيد!';

  @override
  String get language => 'اللغة';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'الإنجليزية';

  @override
  String get refreshDownloads => 'تحديث التحميلات';

  @override
  String downloadingSurah(String surahTitle, String reciterName) {
    return 'جاري تحميل $surahTitle بصوت $reciterName...';
  }

  @override
  String get deleteDownload => 'حذف التحميل';

  @override
  String deleteDownloadConfirmation(String title) {
    return 'هل أنت متأكد من حذف \"$title\"؟';
  }

  @override
  String deleteAllDownloadsConfirmation(String reciterName) {
    return 'هل أنت متأكد من حذف جميع التحميلات لـ $reciterName؟';
  }

  @override
  String get surahs => 'سور';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get welcomeToMuzakri => 'مرحباً بك في مزكري';

  @override
  String get signInWithGoogleDescription => 'سجل الدخول بحساب جوجل للمتابعة';

  @override
  String get signingIn => 'جاري تسجيل الدخول...';

  @override
  String get continueWithGoogle => 'المتابعة مع جوجل';

  @override
  String get googleSignInNotConfigured =>
      'تسجيل الدخول بجوجل غير مُعد. يرجى الاتصال بالدعم.';

  @override
  String get networkError => 'خطأ في الشبكة. يرجى التحقق من اتصالك.';

  @override
  String recitationsAvailable(int count) {
    return '$count رواية متاحة';
  }

  @override
  String loadingReciterSurahs(String reciterName) {
    return 'جاري تحميل سور $reciterName...';
  }
}
