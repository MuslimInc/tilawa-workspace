// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get unknownLocation => 'موقع غير معروف';

  @override
  String get toQibla => 'إلى القبلة';

  @override
  String get north => 'شمال';

  @override
  String get east => 'شرق';

  @override
  String get south => 'جنوب';

  @override
  String get west => 'غرب';

  @override
  String get appTitle => 'تلاوة';

  @override
  String get reciters => 'القراء';

  @override
  String get searchReciters => 'البحث عن القراء...';

  @override
  String get loadingReciters => 'جاري تحميل القراء...';

  @override
  String get searchSurah => 'بحث عن سورة...';

  @override
  String get noRecitersFound => 'لم يتم العثور على قراء';

  @override
  String get noRecitersMatchSearch => 'لا يوجد قراء يطابقون البحث';

  @override
  String a11yOpenReciterDetails(String reciterName) {
    return 'فتح $reciterName';
  }

  @override
  String get a11yFavoriteRecitersOnlyFilter => 'عرض المفضلين فقط';

  @override
  String get recitersShowAllReciters => 'عرض كل القراء';

  @override
  String get a11yRecitersLetterIndex => 'فهرس الحروف';

  @override
  String get a11yRecitersAlphabetScrollbarHint =>
      'اسحب لأعلى أو لأسفل للانتقال إلى حرف';

  @override
  String get showRecitersLetterIndex => 'إظهار فهرس الحروف';

  @override
  String get hideRecitersLetterIndex => 'إخفاء فهرس الحروف';

  @override
  String get recitersMoreActions => 'المزيد';

  @override
  String get recitersLetterIndexMenuItem => 'فهرس الحروف';

  @override
  String recitersResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count قارئ',
      one: 'قارئ واحد',
      zero: 'لا يوجد قراء',
    );
    return '$_temp0';
  }

  @override
  String get recitersFilterChipFavorites => 'المفضلة';

  @override
  String recitersFilterPillFavoritesCount(int count) {
    return 'المفضلة ($count)';
  }

  @override
  String get recitersFilterPillAlphabet => 'أ–ي';

  @override
  String recitersFilterChipLetter(String letter) {
    return 'يبدأ بـ $letter';
  }

  @override
  String recitersFilterChipSearch(String query) {
    return '«$query»';
  }

  @override
  String get a11yClearRecitersSearch => 'مسح نص البحث';

  @override
  String get filteredByLetter => 'مفلتر بالحرف:';

  @override
  String get selectRecitation => 'اختر الرواية';

  @override
  String get loadingSurahList => 'جاري تحميل قائمة السور...';

  @override
  String get noSurahsAvailable => 'لا توجد سور متاحة';

  @override
  String get noSurahsMatchSearch => 'لا توجد سور تطابق البحث';

  @override
  String get continueListening => 'متابعة الاستماع';

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
  String get playingFrom => 'قيد التشغيل من';

  @override
  String get playerQueueExpandHint => 'اسحب لأعلى لعرض القائمة';

  @override
  String get playerQueueHandleSemanticLabel =>
      'إظهار أو إخفاء قائمة التشغيل. اسحب لأعلى أو انقر للتوسيع.';

  @override
  String get playerExpandedSheetSemanticLabel =>
      'التشغيل الآن. اسحب للأسفل للتصغير.';

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
  String get stopPlayback => 'إيقاف التشغيل';

  @override
  String get stopPlaybackConfirmMessage => 'هل أنت متأكد من إيقاف التشغيل؟';

  @override
  String get playerDismissed => 'تم إغلاق المشغل';

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
  String get settingsYourAccount => 'حسابك';

  @override
  String get settingsViewProfile => 'عرض الملف الشخصي';

  @override
  String get settingsLoginSection => 'تسجيل الدخول';

  @override
  String get settingsSupportSection => 'الدعم';

  @override
  String get bottomNavReciters => 'القراء';

  @override
  String get bottomNavSearch => 'بحث';

  @override
  String get a11yBottomNavRecitersTab => 'الانتقال إلى القراء';

  @override
  String get a11yBottomNavRecitersSearch => 'البحث عن قارئ';

  @override
  String recitersSearchResultsFor(String query) {
    return 'نتائج «$query»';
  }

  @override
  String noRecitersForQuery(String query) {
    return 'لا يوجد نتائج لـ «$query»';
  }

  @override
  String get recitersClearSearch => 'مسح البحث';

  @override
  String get bottomNavPrayer => 'الصلاة';

  @override
  String get bottomNavQuran => 'القرآن';

  @override
  String get bottomNavAthkar => 'الأذكار';

  @override
  String get bottomNavSettings => 'الإعدادات';

  @override
  String get audioSettings => 'الصوتيات';

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
  String get playlistName => 'اسم قائمة التشغيل';

  @override
  String get playlistDescription => 'وصف قائمة التشغيل';

  @override
  String get playlistNameHint => 'أدخل اسم قائمة التشغيل';

  @override
  String get playlistDescriptionHint => 'أدخل وصف قائمة التشغيل';

  @override
  String get createNewPlaylist => 'إنشاء قائمة تشغيل جديدة';

  @override
  String get editPlaylist => 'تعديل قائمة التشغيل';

  @override
  String get save => 'حفظ';

  @override
  String get playlistCreated => 'تم إنشاء قائمة التشغيل بنجاح';

  @override
  String get playlistUpdated => 'تم تحديث قائمة التشغيل بنجاح';

  @override
  String get playlistDeleted => 'تم حذف قائمة التشغيل بنجاح';

  @override
  String get deletePlaylist => 'حذف قائمة التشغيل';

  @override
  String get deletePlaylistMessage =>
      'هل أنت متأكد من أنك تريد حذف قائمة التشغيل هذه؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get addToPlaylist => 'إضافة إلى قائمة التشغيل';

  @override
  String get removeFromPlaylist => 'إزالة من قائمة التشغيل';

  @override
  String get playlistItems => 'عناصر قائمة التشغيل';

  @override
  String get playlistDuration => 'المدة';

  @override
  String get playlistItemCount => 'العناصر';

  @override
  String get searchPlaylists => 'البحث في قوائم التشغيل';

  @override
  String get favorites => 'المفضلة';

  @override
  String get clearFavorites => 'مسح المفضلة';

  @override
  String get clearFavoritesConfirmation =>
      'هل أنت متأكد من إزالة جميع القراء من المفضلة؟';

  @override
  String get noFavorites => 'لا توجد مفضلة';

  @override
  String get recent => 'الأحدث';

  @override
  String get public => 'عام';

  @override
  String get private => 'خاص';

  @override
  String get makePublic => 'جعل عام';

  @override
  String get makePrivate => 'جعل خاص';

  @override
  String get duplicatePlaylist => 'نسخ قائمة التشغيل';

  @override
  String get duplicatePlaylistName => 'اسم قائمة التشغيل المنسوخة';

  @override
  String get enterDuplicateName => 'أدخل اسم قائمة التشغيل المنسوخة';

  @override
  String get playlistNameExists => 'قائمة تشغيل بهذا الاسم موجودة بالفعل';

  @override
  String get playlistNameRequired => 'اسم قائمة التشغيل مطلوب';

  @override
  String get playlistDescriptionRequired => 'وصف قائمة التشغيل مطلوب';

  @override
  String get playlistNotFound => 'قائمة التشغيل غير موجودة';

  @override
  String get itemAlreadyInPlaylist => 'العنصر موجود بالفعل في قائمة التشغيل';

  @override
  String get playlistEmpty => 'قائمة التشغيل هذه فارغة';

  @override
  String get playPlaylist => 'تشغيل قائمة التشغيل';

  @override
  String get shufflePlaylist => 'تشغيل عشوائي لقائمة التشغيل';

  @override
  String get playlistStats => 'إحصائيات قائمة التشغيل';

  @override
  String get totalDuration => 'المدة الإجمالية';

  @override
  String get totalItems => 'إجمالي العناصر';

  @override
  String get createdOn => 'تم الإنشاء في';

  @override
  String get lastUpdated => 'آخر تحديث';

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
  String downloadingSurahByReciter(String surahTitle, String reciterName) {
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
  String get welcomeToApp => 'مرحباً بك في تلاوة';

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
  String get unableToSignInWithThirdPartyAccount =>
      'تعذر تسجيل الدخول باستخدام حساب طرف ثالث';

  @override
  String get networkError => 'يرجى التحقق من اتصالك بالإنترنت';

  @override
  String recitationsAvailable(int count) {
    return '$count رواية متاحة';
  }

  @override
  String reciterAdditionalMoshafCount(int count) {
    return ' · $count أخرى';
  }

  @override
  String loadingReciterSurahs(String reciterName) {
    return 'جاري تحميل سور $reciterName...';
  }

  @override
  String get addToFavorites => 'إضافة إلى المفضلة';

  @override
  String get removeFromFavorites => 'إزالة من المفضلة';

  @override
  String get createFirstPlaylistMessage =>
      'أنشئ قائمة التشغيل الأولى لتنظيم السور المفضلة لديك';

  @override
  String get addedToFavorites => 'تمت الإضافة إلى المفضلة';

  @override
  String get removedFromFavorites => 'تمت الإزالة من المفضلة';

  @override
  String get editPlaylistComingSoon => 'ميزة تعديل قائمة التشغيل قادمة قريباً';

  @override
  String get playlistDetailsComingSoon =>
      'شاشة تفاصيل قائمة التشغيل قادمة قريباً';

  @override
  String get playPlaylistComingSoon => 'ميزة تشغيل قائمة التشغيل قادمة قريباً';

  @override
  String get downloadSurahsOffline => 'حمل السور للاستماع دون اتصال';

  @override
  String version(String version) {
    return 'الإصدار $version';
  }

  @override
  String build(String build) {
    return 'النسخة $build';
  }

  @override
  String get notificationWaitingToStart => 'في انتظار البدء...';

  @override
  String notificationDownloadingProgress(int progress) {
    return 'جاري التحميل: $progress%';
  }

  @override
  String get notificationDownloadComplete => 'اكتمل التحميل';

  @override
  String get notificationDownloadFailed => 'فشل التحميل';

  @override
  String notificationBatchDownloadingTitle(int count) {
    return 'جاري تحميل $count ملفات';
  }

  @override
  String notificationBatchProgress(int completed, int total, int progress) {
    return 'التقدم: $completed/$total ($progress%)';
  }

  @override
  String notificationBatchComplete(int count) {
    return 'تم تحميل جميع الملفات بنجاح ($count ملفات)';
  }

  @override
  String get notificationBatchFailed => 'فشل تحميل الملفات';

  @override
  String get resume => 'استئناف';

  @override
  String get appearance => 'المظهر';

  @override
  String get primaryColor => 'لون التطبيق';

  @override
  String get choosePrimaryColor => 'اختر لون التطبيق';

  @override
  String get colorCoral => 'مرجاني';

  @override
  String get colorCyan => 'سماوي';

  @override
  String get colorGreen => 'أخضر';

  @override
  String get colorBrown => 'بني';

  @override
  String get colorPurple => 'أرجواني';

  @override
  String get colorGold => 'ذهبي';

  @override
  String get theme => 'السمة';

  @override
  String get systemTheme => 'النظام الافتراضي';

  @override
  String get lightTheme => 'الوضع الفاتح';

  @override
  String get darkTheme => 'الوضع الداكن';

  @override
  String get chooseTheme => 'اختر السمة';

  @override
  String get chooseLanguage => 'اختر اللغة';

  @override
  String get manageStorage => 'إدارة التخزين';

  @override
  String get manageStorageSubtitle => 'عرض وإدارة المحتوى الذي تم تنزيله';

  @override
  String get concurrentDownloads => 'تنزيلات متزامنة';

  @override
  String concurrentDownloadsSubtitle(int count) {
    return '$count تنزيلات في وقت واحد';
  }

  @override
  String get guestUser => 'زائر';

  @override
  String get signInToSync => 'سجل الدخول لمزامنة بياناتك';

  @override
  String get logoutConfirmation => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get logout => 'تسجيل خروج';

  @override
  String storageUsed(String size) {
    return 'المساحة المستخدمة: $size';
  }

  @override
  String get serverError => 'خطأ في الخادم، يرجى المحاولة مرة أخرى لاحقاً';

  @override
  String get cacheError => 'خطأ في التخزين';

  @override
  String get audioError => 'خطأ في تشغيل الصوت';

  @override
  String get validationError => 'البيانات المُدخلة غير صالحة';

  @override
  String get permissionError => 'تم رفض الإذن';

  @override
  String get unexpectedError => 'حدث خطأ غير متوقع';

  @override
  String get persistenceError => 'فشل في حفظ البيانات';

  @override
  String get uiError => 'خطأ في واجهة المستخدم';

  @override
  String get unknownError => 'حدث خطأ غير معروف';

  @override
  String get startFreeTrial => 'ابدأ التجربة المجانية';

  @override
  String get goHome => 'الذهاب للرئيسية';

  @override
  String pageNotFound(String uri) {
    return 'الصفحة غير موجودة: $uri';
  }

  @override
  String daysRemaining(int days) {
    return 'متبقي $days أيام';
  }

  @override
  String get premiumAccessMessage => 'لديك وصول إلى جميع ميزات بريميوم!';

  @override
  String get upgradeMessage => 'قم بالترقية لفتح ميزات بريميوم';

  @override
  String get freeTrialTitle => 'تجربة مجانية لمدة 7 أيام';

  @override
  String get freeTrialDescription =>
      'جرب جميع ميزات بريميوم لمدة 7 أيام مجانًا تمامًا!';

  @override
  String get anErrorOccurred => 'حدث خطأ ما';

  @override
  String get qiblaAligned => 'أنت تواجه القبلة';

  @override
  String get reciterInfoNotAvailable => 'معلومات القارئ غير متوفرة';

  @override
  String errorLoadingReciter(String error) {
    return 'خطأ في تحميل القارئ: $error';
  }

  @override
  String downloadingSurah(String surahTitle) {
    return 'تحميل $surahTitle';
  }

  @override
  String get home => 'الرئيسية';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get homeLayout => 'تخطيط الصفحة الرئيسية';

  @override
  String get recitersList => 'قائمة القراء';

  @override
  String get chooseHomeLayout => 'اختر تخطيط الصفحة الرئيسية';

  @override
  String get restorePlaybackState => 'استعادة آخر تشغيل';

  @override
  String get restorePlaybackStateSubtitle => 'استئناف الصوت من حيث توقفت';

  @override
  String get timeRemaining => 'الوقت المتبقي';

  @override
  String reciterRemovedFromFavorites(String reciterName) {
    return 'تمت إزالة $reciterName من المفضلة';
  }

  @override
  String get allDownloaded => 'تم التحميل بالكامل';

  @override
  String get undo => 'تراجع';

  @override
  String get athkar => 'الأذكار';

  @override
  String get tasbeehCategory => 'مسبحة';

  @override
  String get tasbeehInputLabel => 'الذكر';

  @override
  String get tasbeehInputHint => 'اكتب ذكرك، مثل: سبحان الله';

  @override
  String get tasbeehSave => 'حفظ';

  @override
  String get tasbeehTapToCount => 'اضغط في أي مكان للزيادة';

  @override
  String get tasbeehTargetLabel => 'الهدف';

  @override
  String get tasbeehSetTarget => 'تعيين الهدف';

  @override
  String get tasbeehAddNewOptionTitle => 'إضافة مسبحة جديدة';

  @override
  String get tasbeehAddNewOptionSubtitle => 'أنشئ الذكر والهدف ثم ابدأ العد';

  @override
  String get tasbeehViewHistoryOptionTitle => 'عرض السجل المحفوظ';

  @override
  String get tasbeehViewHistoryOptionSubtitle => 'اختر من السجل وواصل العد';

  @override
  String get tasbeehGoToCounting => 'ابدأ العد';

  @override
  String get tasbeehBackToOptions => 'العودة للخيارات';

  @override
  String get tasbeehChooseSavedDhikr => 'اختر مسبحة محفوظة';

  @override
  String get tasbeehHistoryEmpty => 'لا توجد مسبحة محفوظة بعد';

  @override
  String tasbeehDeleteConfirmationMessage(String tasbeehText) {
    return 'هل تريد حذف \"$tasbeehText\" من سجل المسبحة المحفوظ؟';
  }

  @override
  String get tasbeehRemoveItem => 'إزالة';

  @override
  String tasbeehCurrentTarget(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'الهدف الحالي: $countString';
  }

  @override
  String get tasbeehSelectOrCreatePrompt =>
      'اختر ذكراً محفوظاً أو أضف ذكراً جديداً للبدء';

  @override
  String get done => 'تم';

  @override
  String get fileSizeUnitB => 'بايت';

  @override
  String get fileSizeUnitKB => 'ك.ب';

  @override
  String get fileSizeUnitMB => 'م.ب';

  @override
  String get fileSizeUnitGB => 'ج.ب';

  @override
  String get fileSizeUnitTB => 'ت.ب';

  @override
  String get reset => 'إعادة ضبط';

  @override
  String get athkarResetConfirmationMessage =>
      'إعادة ضبط عدّاد هذا الذكر؟ سيتم مسح تقدّمك فيه.';

  @override
  String get qibla => 'القبلة';

  @override
  String get qiblaDirection => 'اتجاه القبلة';

  @override
  String get locationServiceDisabled => 'خدمة الموقع معطلة';

  @override
  String get enableLocationServiceMessage =>
      'يرجى تفعيل خدمات الموقع لتحديد اتجاه القبلة.';

  @override
  String get permissionDenied => 'تم رفض الإذن';

  @override
  String get locationPermissionRequiredMessage =>
      'مطلوب إذن الموقع لحساب اتجاه القبلة.';

  @override
  String get downloadAll => 'تحميل الكل';

  @override
  String downloadAllWithCount(int downloaded, int total) {
    final intl.NumberFormat downloadedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String downloadedString = downloadedNumberFormat.format(downloaded);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'تحميل الكل ($downloadedString/$totalString)';
  }

  @override
  String get downloadingAllSurahs => 'جاري تحميل جميع السور...';

  @override
  String completeDownloadingWithCount(int downloaded, int total) {
    final intl.NumberFormat downloadedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String downloadedString = downloadedNumberFormat.format(downloaded);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'استكمال التحميل ($downloadedString/$totalString)';
  }

  @override
  String pauseProgressWithCount(int percent, int downloaded, int total) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);
    final intl.NumberFormat downloadedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String downloadedString = downloadedNumberFormat.format(downloaded);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'إيقاف $percentString% ($downloadedString/$totalString)';
  }

  @override
  String get completeDownloading => 'استكمال التحميل';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get unableToFindQibla => 'تعذر العثور على القبلة';

  @override
  String get qiblaCompassTip => 'تأكد من أن السهم يتحرك عند تحريك الجهاز';

  @override
  String get qiblaCompassAccuracyPoor =>
      'دقة البوصلة منخفضة. حرّك هاتفك على شكل رقم 8 لمعايرتها.';

  @override
  String get onboardingTitle1 => 'دقائق من القرآن…\nيغيّر يومك كله';

  @override
  String get onboardingDesc1 =>
      'ابحث عن آيات تلائم ما تعيشه، وخُذ لنفسك دقائق هادئة للقراءة أو الاستماع.';

  @override
  String get onboardingTitle2 => 'أصوات قرّاء متعددة\nاستمع كما تريد';

  @override
  String get onboardingDesc2 =>
      'قرّاء وروايات مختلفة — اختر الصوت والأسلوب الذي يريحك.';

  @override
  String get onboardingTitle3 => 'كل آية وذكر\nصدقة جارية لأبي حذيفة';

  @override
  String get onboardingDesc3 =>
      'كل ما تسمعه من القرآن وكل ذكر تردّده صدقة جارية لأخينا أبو حذيفة أحمد محمود توني رحمه الله وغفر له.';

  @override
  String onboardingPageSemantics(int current, int total) {
    return 'الشاشة $current من $total';
  }

  @override
  String get onboardingVisualHint2 => 'تصفّح القرّاء مع البحث والمفضلة';

  @override
  String get startJourney => 'ابدأ';

  @override
  String get recitationDuration => 'مدة التلاوة';

  @override
  String get chooseBackgroundSource => 'اختر مصدر الخلفية';

  @override
  String get gallery => 'المعرض';

  @override
  String get camera => 'الكاميرا';

  @override
  String get resetToDefault => 'إعادة ضبط الافتراضي';

  @override
  String get adjustVolume => 'ضبط مستوى الصوت';

  @override
  String get playbackSpeed => 'سرعة التشغيل';

  @override
  String get unknownReciter => 'قارئ غير معروف';

  @override
  String get minutes15 => '15 دقيقة';

  @override
  String get minutes30 => '30 دقيقة';

  @override
  String get minutes60 => '60 دقيقة';

  @override
  String get cancelTimer => 'إلغاء المؤقت';

  @override
  String get custom => 'تخصيص';

  @override
  String get hourLabel => 'ساعة';

  @override
  String get minuteLabel => 'دقيقة';

  @override
  String get enableRecitationDuration => 'مدة التلاوة';

  @override
  String get enableRecitationDurationSubtitle =>
      'إظهار وتفعيل ميزة التحكم في مدة التلاوة';

  @override
  String get sleepTimerActive => 'نشط';

  @override
  String get endOfTrack => 'نهاية المقطع';

  @override
  String get setTimer => 'ضبط المؤقت';

  @override
  String get noInternetConnection => 'لا يوجد اتصال بالإنترنت';

  @override
  String get offlinePlaybackError =>
      'هذا المحتوى غير متاح بدون اتصال. يرجى تنزيله أولاً.';

  @override
  String get offlineFileMissingError =>
      'ملف التنزيل مفقود. يرجى إعادة تنزيل هذا المحتوى.';

  @override
  String get offlineDownloadIncompleteError =>
      'لم يكتمل تنزيل هذا المحتوى. يرجى إكمال التنزيل أولاً.';

  @override
  String get bookmarks => 'العلامات المرجعية';

  @override
  String get addBookmark => 'إضافة علامة مرجعية';

  @override
  String get deleteBookmark => 'حذف العلامة المرجعية';

  @override
  String get editBookmark => 'تعديل العلامة المرجعية';

  @override
  String get searchBookmarks => 'البحث في العلامات المرجعية...';

  @override
  String get noBookmarksYet => 'لا توجد علامات مرجعية بعد';

  @override
  String get noBookmarksDescription =>
      'احفظ لحظاتك المفضلة أثناء الاستماع إلى القرآن';

  @override
  String get bookmarkAdded => 'تمت إضافة العلامة المرجعية';

  @override
  String get bookmarkDeleted => 'تم حذف العلامة المرجعية';

  @override
  String get bookmarkLabel => 'التسمية (اختياري)';

  @override
  String get deleteBookmarkConfirmation =>
      'هل أنت متأكد من حذف هذه العلامة المرجعية؟';

  @override
  String get listeningHistory => 'سجل الاستماع';

  @override
  String get noHistoryYet => 'لا يوجد سجل بعد';

  @override
  String get noHistoryDescription => 'سيظهر سجل الاستماع الخاص بك هنا';

  @override
  String get clearHistory => 'مسح السجل';

  @override
  String get clearHistoryConfirmation => 'هل أنت متأكد من مسح كل سجل الاستماع؟';

  @override
  String get historyDeleted => 'تم حذف السجل';

  @override
  String get totalSurahs => 'إجمالي السور';

  @override
  String get totalListeningTime => 'إجمالي الوقت';

  @override
  String get searchHistory => 'البحث في السجل...';

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String playedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم التشغيل $count مرات',
      one: 'تم التشغيل مرة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get prayerTimes => 'مواقيت الصلاة';

  @override
  String get prayerSettings => 'إعدادات الصلاة';

  @override
  String get fajr => 'الفجر';

  @override
  String get sunrise => 'الشروق';

  @override
  String get dhuhr => 'الظهر';

  @override
  String get asr => 'العصر';

  @override
  String get maghrib => 'المغرب';

  @override
  String get isha => 'العشاء';

  @override
  String get midnight => 'منتصف الليل';

  @override
  String get lastThird => 'الثلث الأخير';

  @override
  String get nextPrayer => 'الصلاة القادمة';

  @override
  String get calculationMethod => 'طريقة الحساب';

  @override
  String get calculationMethodMuslimWorldLeague => 'رابطة العالم الإسلامي';

  @override
  String get calculationMethodEgyptian => 'الهيئة المصرية العامة للمساحة';

  @override
  String get calculationMethodKarachi => 'جامعة العلوم الإسلامية بكراتشي';

  @override
  String get calculationMethodUmmAlQura => 'جامعة أم القرى، مكة المكرمة';

  @override
  String get calculationMethodIsna =>
      ' الجمعية الإسلامية لأمريكا الشمالية (ISNA)';

  @override
  String get calculationMethodTehran => 'معهد الجيوفيزياء بجامعة طهران';

  @override
  String get calculationMethodGulf => 'منطقة الخليج العربي';

  @override
  String get calculationMethodKuwait => 'دولة الكويت';

  @override
  String get calculationMethodQatar => 'دولة قطر';

  @override
  String get calculationMethodSingapore => 'سنغافورة (MUIS)';

  @override
  String get calculationMethodTurkey => 'رئاسة الشؤون الدينية التركية';

  @override
  String get asrCalculation => 'حساب العصر';

  @override
  String get asrCalculationShafii => 'شافعي، مالكي، حنبلي';

  @override
  String get asrCalculationHanafi => 'حنفي';

  @override
  String get displayOptions => 'خيارات العرض';

  @override
  String get use24HourFormat => 'استخدام تنسيق 24 ساعة';

  @override
  String get showSunrise => 'إظهار الشروق';

  @override
  String get showPrayerTimesAlertChipLabels => 'إظهار نص شارات التنبيه';

  @override
  String get locationRequired => 'الموقع مطلوب';

  @override
  String get locationRequiredDescription =>
      'تتطلب مواقيت الصلاة موقعك للحساب بدقة';

  @override
  String get enableLocation => 'تفعيل الموقع';

  @override
  String get updateLocation => 'تحديث الموقع';

  @override
  String get currentLocation => 'الموقع الحالي';

  @override
  String get prayerTimesTodaySchedule => 'جدول اليوم';

  @override
  String get prayerTimesTodayScheduleSubtitle =>
      'الأوقات الأساسية والمؤشرات الليلية';

  @override
  String get prayerTimesRefreshingLocation => 'جارٍ تحديث الموقع...';

  @override
  String get prayerTimesLoading => 'جارٍ تحميل أوقات الصلاة...';

  @override
  String get prayerTimesTapToRefreshLocation => 'اضغط لتحديث الموقع';

  @override
  String prayerTimesTimeRemainingUntil(String prayerName) {
    return 'الوقت المتبقي حتى صلاة $prayerName';
  }

  @override
  String get prayerTimesTimeRemainingCaption => 'الوقت المتبقي';

  @override
  String get prayerTimesScheduled => 'الموعد';

  @override
  String get prayerTimesUpcoming => 'قادمة';

  @override
  String get prayerTimesPassed => 'انتهت';

  @override
  String prayerTimesIqamahAt(String time) {
    return 'الإقامة: $time';
  }

  @override
  String prayerTimesIshraqAt(String time) {
    return 'الإشراق: $time';
  }

  @override
  String get prayerTimesNightMidpointMarker => 'علامة منتصف الليل';

  @override
  String get prayerTimesLastThirdBegins => 'بداية الثلث الأخير';

  @override
  String get hours => 'ساعات';

  @override
  String get minutes => 'دقائق';

  @override
  String get minutesShort => 'دقيقة';

  @override
  String get seconds => 'ثواني';

  @override
  String get at => 'في';

  @override
  String get monthly => 'شهري';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get enableNotifications => 'تفعيل الإشعارات';

  @override
  String minutesBefore(int count) {
    return 'قبل $count دقائق';
  }

  @override
  String get readerSettings => 'إعدادات القراءة';

  @override
  String get fontSize => 'حجم الخط';

  @override
  String get lineHeight => 'ارتفاع السطر';

  @override
  String get fontType => 'نوع الخط';

  @override
  String get showTranslation => 'إظهار الترجمة';

  @override
  String get showAyahNumbers => 'إظهار أرقام الآيات';

  @override
  String get showTransliteration => 'إظهار النطق';

  @override
  String get ayah => 'آية';

  @override
  String get ayahs => 'آيات';

  @override
  String get surahNotFound => 'السورة غير موجودة';

  @override
  String get playAyah => 'تشغيل الآية';

  @override
  String get copyAyah => 'نسخ الآية';

  @override
  String get shareAyah => 'مشاركة الآية';

  @override
  String get searchAyahs => 'البحث في الآيات';

  @override
  String get searchAyahsHint => 'أدخل نص عربي للبحث...';

  @override
  String get enterSearchQuery => 'أدخل كلمة للبحث';

  @override
  String get noResultsFound => 'لم يتم العثور على نتائج';

  @override
  String get close => 'إغلاق';

  @override
  String get continueReading => 'متابعة القراءة';

  @override
  String get lastRead => 'آخر قراءة';

  @override
  String get goToAyah => 'الذهاب إلى الآية';

  @override
  String get juz => 'جزء';

  @override
  String get page => 'صفحة';

  @override
  String get verses => 'آيات';

  @override
  String get meccan => 'مكية';

  @override
  String get medinan => 'مدنية';

  @override
  String get bookmarkUpdated => 'تم تحديث العلامة المرجعية';

  @override
  String get noBookmarksFound => 'لم يتم العثور على علامات مرجعية';

  @override
  String get noBookmarks => 'لا توجد علامات مرجعية';

  @override
  String get tryDifferentSearch => 'جرب كلمة بحث مختلفة';

  @override
  String get noBookmarksHint =>
      'أضف علامة مرجعية للحظاتك المفضلة أثناء الاستماع';

  @override
  String get editBookmarkLabel => 'تعديل تسمية العلامة المرجعية';

  @override
  String get enterBookmarkLabel => 'أدخل تسمية العلامة المرجعية';

  @override
  String get noSearchResults => 'لا توجد نتائج بحث';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get timeAdjustments => 'تعديلات الوقت';

  @override
  String get day => 'يوم';

  @override
  String get features => 'المميزات';

  @override
  String get quranReader => 'قارئ القرآن';

  @override
  String get copiedToClipboard => 'تم النسخ';

  @override
  String get errorPlayingAudio => 'خطأ في تشغيل الصوت';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get welcomeBack => 'مرحباً بعودتك!';

  @override
  String get continueSpiritualJourney => 'أكمل رحلتك الروحانية.';

  @override
  String get recentlyPlayed => 'تم تشغيلها مؤخراً';

  @override
  String get quickAccess => 'وصول سريع';

  @override
  String get dashboardLastRead => 'آخر قراءة';

  @override
  String get dashboardQuran => 'القرآن';

  @override
  String get dashboardDuas => 'الأدعية';

  @override
  String get hifz => 'الحفظ';

  @override
  String get apps => 'التطبيقات';

  @override
  String get donation => 'التبرع';

  @override
  String get todaysActivities => 'أنشطة اليوم';

  @override
  String get dailyActivitiesSubtitle => 'أكمل قائمة الأنشطة اليومية.';

  @override
  String tasksProgress(int completed, int total) {
    return '$completed من $total مهام';
  }

  @override
  String get goToChecklist => 'الذهاب للقائمة';

  @override
  String prayerAwayFrom(String prayer, String time) {
    return 'متبقي على $prayer $time';
  }

  @override
  String get quran => 'القرآن الكريم';

  @override
  String get continueReadingQuran => 'متابعة قراءة القرآن';

  @override
  String get surahIndex => 'فهرس السور';

  @override
  String surahCountLabel(int count) {
    return '$count سورة';
  }

  @override
  String get noSurahsFound => 'لم يتم العثور على سور';

  @override
  String surahProgress(int current, int total) {
    return 'سورة $current / $total';
  }

  @override
  String surahAyahLabel(int surah, int ayah) {
    return 'سورة $surah، آية $ayah';
  }

  @override
  String ayahCountWithPlace(int count, String place) {
    return '$count آية · $place';
  }

  @override
  String get sajda => 'سجدة';

  @override
  String get surahPrefix => 'سورة';

  @override
  String ayahCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count آيات',
      two: 'آيتان',
      one: 'آية واحدة',
    );
    return '$_temp0';
  }

  @override
  String get juzPart => 'الجزء';

  @override
  String get hizb => 'الحزب';

  @override
  String get preparingFonts => 'جاري تجهيز خطوط القرآن الكريم عالية الجودة...';

  @override
  String get loadingQuran => 'جاري تحميل القرآن...';

  @override
  String get fontsDownloadDescription =>
      'هذا التنزيل لمرة واحدة فقط (~50 ميجابايت) للحصول على أفضل تجربة قراءة.';

  @override
  String get fontsFailedToLoad => 'فشل تحميل الخطوط';

  @override
  String get share => 'مشاركة';

  @override
  String get shareScreenshot => 'مشاركة لقطة شاشة';

  @override
  String get shareAudioClip => 'مشاركة مقطع صوتي';

  @override
  String get shareAsText => 'مشاركة كنص';

  @override
  String get shareVerseAudioClip => 'مشاركة صوت الآية';

  @override
  String get fromAyah => 'من الآية';

  @override
  String get toAyah => 'إلى الآية';

  @override
  String get generateAndShare => 'إنشاء ومشاركة';

  @override
  String maxVersesExceeded(int count) {
    return 'الحد الأقصى $count آية لكل مقطع.';
  }

  @override
  String get shareInvalidRangeOrder =>
      'يجب أن تكون الآية الأولى قبل الأخيرة أو مساوية لها.';

  @override
  String get shareInvalidRangeBounds => 'النطاق المحدد خارج هذه السورة.';

  @override
  String get sharing => 'جاري المشاركة...';

  @override
  String get sharedViaTilawa => 'تمت المشاركة عبر تلاوة';

  @override
  String get reciterNotAvailable =>
      'صوت الآيات غير متاح لهذا القارئ. سيتم استخدام القارئ الافتراضي.';

  @override
  String get shareAudio => 'مشاركة مقطع صوتي';

  @override
  String get generateReel => 'إنشاء ريل (فيديو)';

  @override
  String get reviewReel => 'مراجعة الريل';

  @override
  String get shareReel => 'مشاركة الريل';

  @override
  String get shareSheetSubtitle =>
      'اختر الصيغة الأنسب لمشاركة هذه الآيات بصورة جميلة.';

  @override
  String get selectSurahToShare => 'اختر السورة للمشاركة';

  @override
  String get shareScreenshotDescription =>
      'لقطة نظيفة من صفحة المصحف جاهزة للمشاركة.';

  @override
  String get shareAudioClipDescription =>
      'أنشئ مقطع تلاوة أو ريل مصحوبًا بالصوت.';

  @override
  String get audioClipConfigSubtitle =>
      'حدّد نطاق الآيات ثم أنشئ مقطعًا صوتيًا أو ريل عموديًا.';

  @override
  String shareVerseLimit(int count) {
    return 'حتى $count آية لكل مقطع.';
  }

  @override
  String get liveReelPreview => 'معاينة مباشرة للريل';

  @override
  String get createShare => 'إنشاء مشاركة';

  @override
  String get shareComposerSubtitle =>
      'أنشئ مشاركة قرآنية أنيقة مع معاينة مباشرة وتحكمات سهلة.';

  @override
  String get shareReadyTitle => 'جاهز للمشاركة';

  @override
  String get shareReviewSubtitle =>
      'راجع النتيجة النهائية ثم شاركها عندما تراها مناسبة.';

  @override
  String get readyToShare => 'جاهز للمشاركة';

  @override
  String get shareMode => 'صيغة المشاركة';

  @override
  String get shareModeScreenshot => 'صورة';

  @override
  String get shareModeAudio => 'صوت';

  @override
  String get shareModeReel => 'ريل';

  @override
  String get shareStepConfigure => 'الإعداد';

  @override
  String get shareStepGenerating => 'جاري الإنشاء';

  @override
  String get shareStepReview => 'المراجعة';

  @override
  String get shareContentLayout => 'نمط المحتوى';

  @override
  String get shareLayoutReaderPage => 'صفحة القارئ';

  @override
  String get shareLayoutPassageCard => 'بطاقة الآيات';

  @override
  String get shareReaderPageHint =>
      'تستخدم صفحة القارئ الصفحة الحالية كما تظهر داخل القارئ تمامًا.';

  @override
  String get shareDuration => 'مدة المقطع';

  @override
  String get shareDurationAuto => 'النطاق الكامل';

  @override
  String get shareDurationShort => '30 ثانية';

  @override
  String get shareDurationMedium => '60 ثانية';

  @override
  String get shareDurationLong => '90 ثانية';

  @override
  String get shareDurationHint =>
      'تحافظ خيارات المدة على اكتمال الآيات عندما تكون بيانات التوقيت متاحة.';

  @override
  String get prepareScreenshot => 'تجهيز الصورة';

  @override
  String get prepareAudioClip => 'تجهيز المقطع الصوتي';

  @override
  String get prepareReel => 'تجهيز الريل';

  @override
  String get preparingScreenshot => 'جارِ تجهيز الصورة...';

  @override
  String get preparingAudioClip => 'جارِ تجهيز المقطع الصوتي...';

  @override
  String get preparingReelStatus => 'جارِ تجهيز الريل...';

  @override
  String get generatingAudioClipStatus => 'جارِ إنشاء المقطع الصوتي...';

  @override
  String get capturingReaderVisuals => 'جارِ التقاط مشهد القارئ...';

  @override
  String get combiningReelMedia => 'جارِ دمج المشهد والصوت في ريل...';

  @override
  String get preparingToTrimLocalAudio => 'جارِ تجهيز قص الصوت المحلي...';

  @override
  String get reciterNotSupportedForLocalTrim =>
      'هذا القارئ غير مدعوم للقص المحلي. سيتم التحويل إلى التنزيل عبر الإنترنت...';

  @override
  String get fetchingAyahTimings => 'جارِ جلب توقيت الآيات...';

  @override
  String get noTimingsFound =>
      'لم يتم العثور على توقيتات. سيتم التحويل إلى التنزيل عبر الإنترنت...';

  @override
  String get noTimingsFoundForRange =>
      'لم يتم العثور على توقيتات للنطاق المحدد. سيتم التحويل إلى التنزيل عبر الإنترنت...';

  @override
  String get trimmingAudio => 'جارِ قص الصوت...';

  @override
  String get generatedAudioFileNotFound =>
      'لم يتم العثور على ملف الصوت الذي تم إنشاؤه.';

  @override
  String get generatedReelFileNotFound =>
      'لم يتم العثور على ملف الريل الذي تم إنشاؤه.';

  @override
  String downloadingVerseProgress(int currentVerse, int totalVerses) {
    return 'جارِ تنزيل الآية $currentVerse من $totalVerses...';
  }

  @override
  String get assemblingAudioClip => 'جارِ تجميع المقطع الصوتي...';

  @override
  String get preparingVideoEncoding => 'جارِ تجهيز ترميز الفيديو...';

  @override
  String get encodingVerticalVideo =>
      'جارِ ترميز الفيديو العمودي، قد يستغرق ذلك بعض الوقت...';

  @override
  String get reelGenerationFailed =>
      'تعذّر إنشاء فيديو الريل. يرجى المحاولة مرة أخرى.';

  @override
  String get reelGenerationFailedInvalidFrame =>
      'تعذّر معالجة إطار الصورة الملتقطة لإنشاء الريل. يرجى إعادة المحاولة.';

  @override
  String get reelGenerationFailedMissingScreenshot =>
      'لم يتم العثور على إطار ملتقط لإنشاء الريل.';

  @override
  String get reelGenerationFailedInvalidOutput =>
      'ملف الريل الناتج غير صالح ولا يمكن فتحه. يرجى إعادة المحاولة.';

  @override
  String get reelPreviewLoadFailed => 'تعذّر تحميل معاينة الفيديو الناتج.';

  @override
  String get reelGenerated => 'تم إنشاء الريل!';

  @override
  String get shareReviewTitle => 'راجع المشاركة';

  @override
  String get shareReviewScreenshot => 'الصورة جاهزة للمشاركة.';

  @override
  String get shareReviewAudio => 'المقطع الصوتي جاهز للمشاركة.';

  @override
  String get shareReviewReel => 'الريل جاهز للمشاركة.';

  @override
  String shareDurationPresetLabel(int seconds) {
    return 'حتى $seconds ثانية';
  }

  @override
  String get edit => 'تعديل';

  @override
  String get prayerNotifications => 'إشعارات الصلاة';

  @override
  String get manageAlerts => 'إدارة التنبيهات';

  @override
  String get prayerNotificationsEnabledAll => 'جميع إشعارات الصلاة';

  @override
  String get playAdhan => 'تشغيل الأذان';

  @override
  String get atPrayerTime => 'عند وقت الصلاة';

  @override
  String get exactAlarmPermissionRequired =>
      'إذن التنبيه الدقيق مطلوب لضمان دقة إشعارات الصلاة.';

  @override
  String get notificationPermissionRequired =>
      'إذن الإشعارات مطلوب لاستلام تذكيرات الصلاة.';

  @override
  String get batteryOptimizationExemptionRequired =>
      'أوقف تحسين البطارية حتى تصلك إشعارات الصلاة في وقتها أثناء إيقاف الشاشة.';

  @override
  String get oemAutostartHint =>
      'في هذا الجهاز، فعّل أيضاً التشغيل التلقائي لتطبيق تلاوة من إعدادات الهاتف حتى لا تتوقف التذكيرات في الخلفية.';

  @override
  String prayerNotificationBody(String prayerName) {
    return 'حان وقت $prayerName';
  }

  @override
  String get prayerNotificationsChannelName => 'أوقات الصلاة';

  @override
  String get prayerNotificationsChannelDescription =>
      'تذكيرات بأوقات الصلوات الخمس';

  @override
  String get prayerNotificationsAdhanChannelName => 'أوقات الصلاة (الأذان)';

  @override
  String get prayerNotificationsAdhanChannelDescription =>
      'تذكيرات الصلاة التي تشغل صوت الأذان';

  @override
  String get prayerNotificationsSilentAdhanChannelName =>
      'مواقيت الصلاة (صامت)';

  @override
  String get prayerNotificationsSilentAdhanChannelDescription =>
      'تنبيهات صامتة لمواقيت الصلاة عند تشغيل الأذان محلياً';

  @override
  String get adhanIsPlaying => 'الأذان يعمل الآن';

  @override
  String get stopAdhan => 'إيقاف الأذان';

  @override
  String get adhanStillPlayingMessage => 'هل تريد إيقاف الأذان قبل المغادرة؟';

  @override
  String get prayerNotificationReceived => 'تنبيه الصلاة';

  @override
  String get viewAllPrayerTimes => 'عرض جميع مواقيت الصلاة';

  @override
  String prayerTimeAt(String time) {
    return 'الساعة $time';
  }

  @override
  String get prayerAlertModeOff => 'متوقف';

  @override
  String get prayerAlertModeNotifyOnly => 'تنبيه فقط';

  @override
  String get prayerAlertModeAdhan => 'الأذان';

  @override
  String get prayerAlertModeOffDescription =>
      'لا يوجد تنبيه أو أذان لهذه الصلاة.';

  @override
  String get prayerAlertModeNotifyOnlyDescription =>
      'إظهار تنبيه وقت الصلاة بدون أذان.';

  @override
  String get prayerAlertModeAdhanDescription => 'إظهار تنبيه وتشغيل الأذان.';

  @override
  String get notificationStatus => 'التنبيه';

  @override
  String get adhanStatus => 'الأذان';

  @override
  String get received => 'تم الاستلام';

  @override
  String get sound => 'الصوت';

  @override
  String get enabled => 'مفعل';

  @override
  String get disabled => 'معطل';

  @override
  String get errorMissingNotificationPayload => 'بيانات التنبيه مفقودة.';

  @override
  String get errorInvalidNotificationPayload => 'بيانات التنبيه غير صالحة.';

  @override
  String get moreOptions => 'المزيد';

  @override
  String get supportTilawa => 'ادعم تلاوة';

  @override
  String get rateTilawa => 'قيّم تلاوة';

  @override
  String get rateTilawaSubtitle => 'شاركنا رأيك في متجر التطبيقات.';

  @override
  String get shareTilawa => 'شارك تلاوة';

  @override
  String shareTilawaMessage(String appName, String storeUrl) {
    return 'جرّب $appName:\n$storeUrl';
  }

  @override
  String get shareTilawaFailed => 'تعذر فتح نافذة المشاركة. حاول مرة أخرى.';

  @override
  String get supportIntroLine => 'مشاركتك تساعدنا على استمرار تلاوة.';

  @override
  String get supportTilawaSubtitle => 'مشاركتك تساعدنا على استمرار تلاوة.';

  @override
  String get supportMissionBody => 'مشاركتك تساعدنا على استمرار تلاوة.';

  @override
  String get supportImpactWhyTitle => 'لماذا؟';

  @override
  String get supportImpactTitle => 'أين تذهب مشاركتك';

  @override
  String get supportImpactQuranHosting => 'المصحف والتلاوات الصوتية';

  @override
  String get supportImpactReciterAudio => 'المصحف والتلاوات الصوتية';

  @override
  String get supportImpactPrayerTools => 'مواقيت الصلاة والأدوات';

  @override
  String get supportImpactDevelopment => 'التشغيل والتطوير';

  @override
  String get supportImpactAdFree => 'التشغيل والتطوير';

  @override
  String get supportTierSmall => 'يسير';

  @override
  String get supportTierKind => 'كريم';

  @override
  String get supportTierGenerous => 'وافر';

  @override
  String get supportContinueWithPlay => 'متابعة على Google Play';

  @override
  String get supportConfirmationTitle => 'تأكيد';

  @override
  String get supportConfirmationBody =>
      'يتم الدفع عبر Google Play. تلاوة لا يحتفظ ببيانات بطاقتك.';

  @override
  String get supportConfirm => 'متابعة';

  @override
  String get supportCancel => 'إلغاء';

  @override
  String get supportThankYouTitle => 'شكرًا جزيلًا';

  @override
  String get supportThankYouBody => 'وصلت مشاركتك. نقدّر ثقتك.';

  @override
  String get supportDone => 'تم';

  @override
  String get supportRestorePurchases => 'استعادة';

  @override
  String get supportRestoreHint =>
      'إن لم تُكتمل عملية دفع سابقة، اضغط «استعادة».';

  @override
  String get supportTrustLinePrefix =>
      'الدفع عبر Google Play · يُوجَّه جزء من المبلغ إلى منظمة تلاوة التقنية وجمعيات خيرية (';

  @override
  String get supportCharitiesLinkLabel => 'رابط الجمعيات الخيرية';

  @override
  String get supportCharitiesSheetTitle => 'الجمعيات الخيرية الشريكة';

  @override
  String get supportCharityDarAlArqam => 'دار الأرقم لتحفيظ القرآن';

  @override
  String get supportCharityIslaheg => 'مؤسسة الإصلاح الخيرية';

  @override
  String get supportTrustLineSuffix => ')';

  @override
  String get supportTrustLine =>
      'الدفع عبر Google Play · يُوجَّه جزء من المبلغ إلى منظمة تلاوة التقنية وجمعيات خيرية (رابط الجمعيات الخيرية)';

  @override
  String get supportPlayFooter =>
      'الدفع عبر Google Play · يُوجَّه جزء من المبلغ إلى منظمة تلاوة التقنية وجمعيات خيرية (رابط الجمعيات الخيرية)';

  @override
  String get supportDisclaimer =>
      'الدفع عبر Google Play · يُوجَّه جزء من المبلغ إلى منظمة تلاوة التقنية وجمعيات خيرية (رابط الجمعيات الخيرية)';

  @override
  String get supportOfflineMessage => 'يلزم اتصال بالإنترنت.';

  @override
  String get supportBillingUnavailable =>
      'الدفع عبر Google Play غير متاح على هذا الجهاز.';

  @override
  String get supportProductsUnavailable =>
      'الخيارات غير متاحة حاليًا. جرّب لاحقًا.';

  @override
  String get supportPurchasePending => 'قيد المعالجة في Google Play.';

  @override
  String get supportPurchaseVerifyFailed => 'تعذّر التأكيد. جرّب «استعادة».';

  @override
  String get supportRestoreNothingFound => 'لا توجد عملية سابقة لهذا الحساب.';

  @override
  String get supportRestoreComplete => 'تمت الاستعادة.';

  @override
  String get supportSelectTier => 'اختر المبلغ';

  @override
  String get supportSettingsGroupTitle => 'ادعم تلاوة';

  @override
  String get supportHelpKeepFree => 'اختياري';

  @override
  String get purchaseBillingUnavailable => 'الدفع غير متاح حاليًا.';

  @override
  String get purchaseProductNotFound => 'هذا الخيار غير متاح.';

  @override
  String get purchaseVerificationFailed =>
      'تعذّر التأكيد. أعد المحاولة لاحقًا.';

  @override
  String get purchasePending => 'ما زالت قيد المعالجة.';

  @override
  String get purchaseAlreadyOwned => 'تمت هذه المشاركة مسبقًا.';

  @override
  String get appReviewUnavailable =>
      'التقييمات غير متاحة على هذا الجهاز حاليًا.';

  @override
  String get appReviewRequestFailed => 'تعذر فتح نافذة التقييم. حاول مرة أخرى.';

  @override
  String get appReviewStoreListingFailed =>
      'تعذر فتح متجر التطبيقات. حاول مرة أخرى.';

  @override
  String get appReviewPlatformUnsupported =>
      'تقييمات المتجر غير مدعومة على هذه المنصة.';

  @override
  String get a11ySplashLoading => 'تلاوة، جارٍ التحميل';

  @override
  String get splashSlowLoadingNotice => 'قد يستغرق بعض المحتوى لحظة للتحميل';

  @override
  String get tourActionNext => 'التالي';

  @override
  String get tourActionFinish => 'تم';

  @override
  String get tourActionSkip => 'تخطٍّ';

  @override
  String tourStepSemantics(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get tourRecitersSearchTitle => 'ابحث عن قارئ';

  @override
  String get tourRecitersSearchDescription =>
      'ابحث بالاسم للوصول السريع إلى أي قارئ.';

  @override
  String get tourRecitersFavoritesTitle => 'احفظ المفضّلين';

  @override
  String get tourRecitersFavoritesDescription =>
      'اضغط على القلب لإبقاء القرّاء المفضّلين لديك في متناول يدك.';

  @override
  String get tourRecitersOpenReciterTitle => 'افتح قارئًا';

  @override
  String get tourRecitersOpenReciterDescription =>
      'اضغط على قارئ لتصفّح تلاواته وبدء الاستماع.';

  @override
  String get tourReciterPlaybackPlayingTitle => 'قيد التشغيل الآن';

  @override
  String get tourReciterPlaybackPlayingDescription =>
      'السورة المميّزة تُشغَّل الآن. اضغط على أي سورة للتبديل.';

  @override
  String get tourReciterPlaybackMiniPlayerTitle => 'المشغّل المصغّر';

  @override
  String get tourReciterPlaybackMiniPlayerDescription =>
      'تحكّم في التشغيل من هنا أثناء متابعة التصفّح.';

  @override
  String get tourDebugResetTitle => 'إعادة تعيين الجولات التعريفية';

  @override
  String get tourDebugResetDone => 'تمت إعادة تعيين الجولات التعريفية';
}
