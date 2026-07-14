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
  String get appTitle => 'أنا مسلم';

  @override
  String get reciters => 'القراء';

  @override
  String get searchReciters => 'البحث عن القراء...';

  @override
  String get loadingReciters => 'جاري تحميل القراء...';

  @override
  String get homeTitle => 'الصفحة الرئيسية';

  @override
  String get homeGreeting => 'السلام عليكم';

  @override
  String get homeInspirationTitle => 'إلهام اليوم';

  @override
  String get homeInspirationSubtitle => 'آية ودعاء لقلبك';

  @override
  String homeGreetingName(String name) {
    return 'السلام عليكم، $name';
  }

  @override
  String get homeProfileLabel => 'ملف المستخدم';

  @override
  String get homeLocationUnavailable => 'حدّد الموقع';

  @override
  String get homeHeroLocationContext => 'الصلاة في';

  @override
  String get homeNextPrayerUnavailable =>
      'حدّد موقعك لمعرفة موعد الصلاة القادمة.';

  @override
  String get homePrayerTimesAction => 'مواقيت الصلاة';

  @override
  String get homePrayerNow => 'حان وقت الأذان';

  @override
  String get homeSunriseNow => 'حان وقت الشروق';

  @override
  String get homeDuhaNow => 'حان وقت الضحى';

  @override
  String homePrayerInMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'بعد $minutes دقائق',
      two: 'بعد دقيقتين',
      one: 'بعد دقيقة',
    );
    return '$_temp0';
  }

  @override
  String homePrayerInHoursMinutes(int hours, int minutes) {
    return 'بعد $hours س $minutes د';
  }

  @override
  String get homeExploreTitle => 'اكتشف';

  @override
  String get homeExploreSubtitle => 'أدواتك اليومية بلمحة';

  @override
  String get homeKhatmaCarouselSubtitle => 'تقدّم في ختمتك';

  @override
  String get homeSupportCarouselSubtitle =>
      'ساهِم في إبقاء تلاوة مجانية للجميع';

  @override
  String get homeHistoryCarouselSubtitle => 'تابع من حيث توقّفت';

  @override
  String get homeFavoritesCarouselSubtitle => 'تلاواتك وسورك المحفوظة';

  @override
  String get homeDownloadsCarouselSubtitle => 'استمع بلا إنترنت';

  @override
  String get homeSessionsTitle => 'تعلّم التلاوة';

  @override
  String get homeSessionsSubtitle => 'جلسات مخصصة مع محفظ معتمد';

  @override
  String get homeExploreShowAsList => 'عرض كقائمة';

  @override
  String get homeExploreShowAsGrid => 'عرض كشبكة';

  @override
  String get homeDashboardLoadError =>
      'تعذّر تحميل المواقيت. تحقق من اتصالك وحاول مجددًا.';

  @override
  String get homeDashboardOfflineError =>
      'أنت غير متصل ولا توجد مواقيت محفوظة بعد. أعد الاتصال وحاول مجددًا.';

  @override
  String get homeRefreshOfflineMessage =>
      'أنت غير متصل. نعرض آخر بيانات محفوظة لديك.';

  @override
  String get homeRefreshFailedMessage =>
      'تعذّر التحديث. ما زالت آخر بيانات محفوظة لديك معروضة.';

  @override
  String get homeSearchHint => 'ابحث في السور أو الأجزاء أو الصفحة';

  @override
  String get homeFeaturedTitle => 'مختارة لك';

  @override
  String get homeFeaturedSubtitle => 'المزيد ليومك';

  @override
  String get homeTodayTitle => 'اليوم';

  @override
  String get homeYoursTitle => 'خاصتك';

  @override
  String homeListeningResumeSubtitle(String reciter, String surah) {
    return '$reciter · $surah';
  }

  @override
  String get homeAthkarDone => 'تم';

  @override
  String homeAthkarRemaining(int count) {
    return 'متبقٍ $count';
  }

  @override
  String get homeAthkarNotStarted => 'لم يبدأ';

  @override
  String homeQuranStreakDays(int days) {
    return 'سلسلة $days أيام';
  }

  @override
  String homeQuranGoalProgress(int percent) {
    return '$percent% من هدف اليوم';
  }

  @override
  String get homeDailyAyahBookmark => 'حفظ';

  @override
  String get homeDailyAyahShare => 'مشاركة';

  @override
  String get homeTodaySubtitle => 'الصلاة والقرآن والذكر ليومك';

  @override
  String get homeContinueTitle => 'تابع';

  @override
  String get homeDailyPracticeTitle => 'الممارسة اليومية';

  @override
  String get homeDailyPracticeSubtitle => 'أذكارك المثبتة وأدعيتك';

  @override
  String get homeDailyHabitTitle => 'العادة اليومية';

  @override
  String get homeDailyHabitSubtitle => 'ابدأ أو أكمل أذكارك';

  @override
  String get homeAthkarRitualsTitle => 'أذكار سريعة';

  @override
  String get homePrayerStripTitle => 'مواقيت اليوم';

  @override
  String get homePrayerStripViewAll => 'عرض الكل';

  @override
  String get homeFeaturedRitualStart => 'اضغط للبدء';

  @override
  String get homeStartQuranTitle => 'افتح المصحف';

  @override
  String get homeStartQuranSubtitle => 'ابدأ قراءة القرآن اليوم';

  @override
  String get homeContinueQuranTitle => 'تابع القرآن';

  @override
  String get homeContinueQuranSubtitle => 'ارجع إلى آخر صفحة قرأتها';

  @override
  String homeQuranResumeSurahPage(String surah, int page) {
    return '$surah · صفحة $page';
  }

  @override
  String homeQuranResumePage(int page) {
    return 'صفحة $page';
  }

  @override
  String homeQuranResumeProgress(int percent) {
    return '$percent٪ من المصحف';
  }

  @override
  String homeContextualAthkarPrompt(String name) {
    return 'وقت مناسب لـ $name';
  }

  @override
  String get homeAthkarNowBadge => 'الآن';

  @override
  String get experimentalBadgeLabel => 'تجريبي';

  @override
  String get homeQuickQuran => 'القرآن';

  @override
  String get homeQuickActionsTitle => 'إجراءات سريعة';

  @override
  String get homeMainActionsTitle => 'عباداتك اليومية';

  @override
  String get homeQuickToolsTitle => 'أدوات سريعة';

  @override
  String get homeLearningBrowseTitle => 'تعلّم القرآن';

  @override
  String get homeLearningBrowseSubtitle =>
      'اختر محفظك واحجز جلسة مباشرة فردية.';

  @override
  String get homeLearningBrowseCta => 'ابدأ التعلّم';

  @override
  String get homeLearningInterestPromptTitle =>
      'هل ترغب في تعلّم القرآن مع محفظ؟';

  @override
  String get homeLearningInterestPromptSubtitle =>
      'أتقن التلاوة والتجويد بشكل فردي (1-على-1) مع توجيه مباشر.';

  @override
  String get homeLearningInterestPromptYes => 'نعم، مهتم';

  @override
  String get homeLearningInterestPromptNo => 'ليس الآن';

  @override
  String get homeLearningNextSessionTitle => 'جلسة القرآن القادمة';

  @override
  String homeLearningNextSessionStartsIn(int minutes) {
    return 'تبدأ خلال $minutes دقيقة';
  }

  @override
  String get homeLearningNextSessionLive => 'مباشر الآن';

  @override
  String get homeLearningPendingBookingTitle => 'حجز معلم معلق';

  @override
  String get homeLearningPendingBookingApproval => 'بانتظار موافقة المعلم';

  @override
  String get homeLearningPendingBookingPayment => 'بانتظار الدفع';

  @override
  String get homeLearningRevisionTitle => 'مواصلة التعلم';

  @override
  String get settingsTeacherApplicationEntryTitle => 'التقديم كمعلّم قرآن';

  @override
  String get settingsTeacherApplicationEntrySubtitle =>
      'إذا كنت محفّظًا أو لديك خبرة في تعليم القرآن، يمكنك إرسال طلبك للمراجعة.';

  @override
  String get teacherApplicationOpenFormCta => 'فتح نموذج التقديم';

  @override
  String get teacherApplicationSheetTitle => 'هل أنت محفّظ أو معلّم قرآن؟';

  @override
  String get teacherApplicationSheetBody =>
      'نستقبل الآن طلبات المحفّظين والمعلّمين ذوي الخبرة للمشاركة في ميزة تعلّم القرآن داخل التطبيق. يمكنك تعبئة نموذج التقديم، وسيقوم فريقنا بمراجعته قبل تفعيل أي صلاحيات.';

  @override
  String get teacherApplicationLaterCta => 'لاحقاً';

  @override
  String get teacherApplicationFormOpenFailed =>
      'تعذّر فتح نموذج التقديم. حاول مرة أخرى.';

  @override
  String get homeQuickQuranReader => 'المصحف';

  @override
  String get homeQuickQuranReaderSubtitle => 'اقرأ القرآن بتدبّر';

  @override
  String get homeLearnQuranWithTutor => 'تعلّم القرآن مع محفظك';

  @override
  String get homeQuickReciters => 'القرّاء';

  @override
  String get homeQuickRecitersSubtitle => 'استمع لتلاوات مختارة';

  @override
  String get homeQuickPrayer => 'الصلاة';

  @override
  String get homeQuickQibla => 'القبلة';

  @override
  String get homeQuickQiblaSubtitle => 'اتجه نحو القبلة بسهولة';

  @override
  String get homeQuickSettingsSubtitle => 'المظهر والصوت والحساب';

  @override
  String get homeQuickTasbeeh => 'التسبيح';

  @override
  String get homeQuickTasbeehSubtitle => 'سبّح واذكر الله بلمسة';

  @override
  String get homeQuickAthkar => 'الأذكار';

  @override
  String get homeQuickAthkarSubtitle => 'وردك اليومي من الأذكار';

  @override
  String get homeQuickSettings => 'الإعدادات';

  @override
  String get homePinnedAthkarTitle => 'أذكارك السريعة';

  @override
  String get homePinnedAthkarEdit => 'تعديل اختصارات الأذكار';

  @override
  String get homePinnedAthkarChoose => 'اختر الأذكار';

  @override
  String get homePinnedAthkarEmptyTitle => 'اختر أذكارك اليومية';

  @override
  String get homePinnedAthkarEmptyBody =>
      'ثبّت حتى أربعة تصنيفات للوصول إليها من الصفحة الرئيسية بلمسة واحدة.';

  @override
  String get homePinnedAthkarPickerTitle => 'اختر الأذكار السريعة';

  @override
  String homePinnedAthkarPickerLimit(int count, int max) {
    return 'تم اختيار $count من $max اختصارات';
  }

  @override
  String homePinnedAthkarMoveUp(String name) {
    return 'انقل $name للأعلى';
  }

  @override
  String homePinnedAthkarMoveDown(String name) {
    return 'انقل $name للأسفل';
  }

  @override
  String get homeDailyInspirationTitle => 'إلهام اليوم';

  @override
  String get homeDailyInspirationSubtitle => 'آية ودعاء ليومك';

  @override
  String get homeDailyAyahLabel => 'آية اليوم';

  @override
  String get homeDailyAyahBody =>
      'وَأَقِيمُوا الصَّلَاةَ وَآتُوا الزَّكَاةَ وَارْكَعُوا مَعَ الرَّاكِعِينَ';

  @override
  String get homeDailyAyahReference => 'القرآن ٢:٤٣';

  @override
  String get homeDailyDuaLabel => 'دعاء اليوم';

  @override
  String get homeDailyDuaBody => 'اللهم أعني على ذكرك وشكرك وحسن عبادتك.';

  @override
  String get homeDailyDuaReference => 'أبو داود';

  @override
  String get homeDailyAyahBody1 =>
      'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ';

  @override
  String get homeDailyAyahReference1 => 'القرآن ٢:١٥٢';

  @override
  String get homeDailyDuaBody1 =>
      'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ';

  @override
  String get homeDailyDuaReference1 => 'القرآن ٢:٢٠١';

  @override
  String get homeDailyAyahBody2 =>
      'إِنَّ الصَّلَاةَ تَنْهَىٰ عَنِ الْفَحْشَاءِ وَالْمُنكَرِ';

  @override
  String get homeDailyAyahReference2 => 'القرآن ٢٩:٤٥';

  @override
  String get homeDailyDuaBody2 =>
      'اللهم إني أسألك علماً نافعاً، ورزقاً طيباً، وعملاً متقبلاً';

  @override
  String get homeDailyDuaReference2 => 'ابن ماجه';

  @override
  String get khatmaEmptyTitle => 'ابدأ ختمة جديدة';

  @override
  String get khatmaEmptySubtitle =>
      'حدّد بداية الختمة ونهايتها والمدة المناسبة لك، وسنقسّمها إلى ورد يومي.';

  @override
  String khatmaDurationDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يومًا',
      two: 'يومان',
      one: 'يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String get khatmaProgressTitle => 'تقدّم الختمة';

  @override
  String khatmaProgressSubtitle(int currentDay, int totalDays) {
    return 'اليوم $currentDay من $totalDays';
  }

  @override
  String get khatmaProgressPercent => 'التقدّم';

  @override
  String get khatmaTodayGoal => 'اليوم';

  @override
  String get khatmaRemaining => 'المتبقي';

  @override
  String khatmaPagesShort(int pages) {
    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: '$pages صفحات',
      two: 'صفحتان',
      one: 'صفحة',
    );
    return '$_temp0';
  }

  @override
  String khatmaDaysShort(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days أيام',
      two: 'يومان',
      one: 'يوم',
    );
    return '$_temp0';
  }

  @override
  String get khatmaAdjustedPlan => 'عدّلنا خطتك بلطف لهذا اليوم.';

  @override
  String khatmaContinueFromPage(int page) {
    return 'تابع من صفحة $page';
  }

  @override
  String get khatmaRemainingPages => 'صفحات متبقية';

  @override
  String get khatmaCatchUpAction => 'عوّض اليوم';

  @override
  String get khatmaExtendAction => 'مدّد الخطة';

  @override
  String get khatmaResetAction => 'إعادة ضبط الخطة';

  @override
  String get khatmaResetTitle => 'حذف خطة الختمة؟';

  @override
  String get khatmaResetMessage =>
      'سيتم حذف الخطة الحالية فقط. ستظل آخر صفحة قرأتها وعلاماتك المرجعية محفوظة.';

  @override
  String get khatmaContinueReading => 'تابع القراءة';

  @override
  String get khatmaHubTitle => 'ختمة ذكية';

  @override
  String get khatmaHomeViewPlan => 'عرض الخطة';

  @override
  String get khatmaHubResetSubtitle => 'يحذف الخطة فقط، وتبقى علاماتك محفوظة';

  @override
  String get khatmaCompletedTitle => 'اكتملت الختمة';

  @override
  String get khatmaProgressCompleteMetric => '١٠٠٪';

  @override
  String get khatmaCompletedSubtitle =>
      'تقبّل الله منك. ابدأ خطة جديدة حين تكون مستعدًا.';

  @override
  String get khatmaStartAnotherAction => 'ابدأ ختمة أخرى';

  @override
  String get khatmaUnavailable => 'خطة الختمة غير متاحة مؤقتًا. حاول مرة أخرى.';

  @override
  String get khatmaStartFromBeginning => 'من البداية';

  @override
  String get khatmaContinueCurrentPosition => 'من موضعي الحالي في القرآن';

  @override
  String get khatmaReviewPlanTitle => 'راجع خطة الختمة';

  @override
  String khatmaRangePages(int startPage, int endPage) {
    return 'الصفحات $startPage–$endPage';
  }

  @override
  String khatmaRangePagesFormatted(String range) {
    return 'الصفحات $range';
  }

  @override
  String khatmaDailyPages(int pages) {
    return '$pages صفحات يوميًا';
  }

  @override
  String khatmaStartPage(int page) {
    return 'تبدأ من الصفحة $page';
  }

  @override
  String khatmaTargetPage(int page) {
    return 'تنتهي عند الصفحة $page';
  }

  @override
  String khatmaExpectedCompletionDate(String date) {
    return 'موعد الإتمام المتوقع: $date';
  }

  @override
  String get khatmaConfirmPlanAction => 'ابدأ هذه الختمة';

  @override
  String get khatmaStartTodayAction => 'ابدأ ورد اليوم';

  @override
  String get khatmaResumeTodayAction => 'تابع ورد اليوم';

  @override
  String get khatmaTodayCompletedTitle => 'اكتمل ورد اليوم';

  @override
  String get khatmaTodayCompletedSubtitle => 'سيكون وردك التالي جاهزًا غدًا.';

  @override
  String khatmaConfirmedAndRemaining(int confirmed, int remaining) {
    return 'أكملت $confirmed · متبقي $remaining';
  }

  @override
  String get khatmaSaveProgressTitle => 'احفظ تقدّم الختمة';

  @override
  String khatmaCompletedThroughPage(int page) {
    return 'أتممت القراءة حتى الصفحة $page';
  }

  @override
  String get khatmaProgressPageSelector => 'اختر آخر صفحة أتممت قراءتها';

  @override
  String get khatmaCompleteTodayAction => 'أتممت ورد اليوم';

  @override
  String khatmaSaveThroughPageAction(int page) {
    return 'حفظ التقدّم حتى الصفحة $page';
  }

  @override
  String get khatmaExtendReviewTitle => 'راجع تمديد الخطة';

  @override
  String khatmaExtendReviewMessage(
    int oldPages,
    int newPages,
    String oldDate,
    String newDate,
  ) {
    return 'الصفحات يوميًا: $oldPages ← $newPages\nموعد الإتمام: $oldDate ← $newDate';
  }

  @override
  String get khatmaCreateAction => 'إنشاء ختمة';

  @override
  String get khatmaBoundaryBySurah => 'نطاق السور';

  @override
  String get khatmaBoundaryByPage => 'نطاق الصفحات';

  @override
  String get khatmaStartSurah => 'سورة البداية';

  @override
  String get khatmaEndSurah => 'سورة النهاية';

  @override
  String get khatmaStartPageInput => 'صفحة البداية';

  @override
  String get khatmaEndPageInput => 'صفحة النهاية';

  @override
  String get khatmaPageBoundsHelp => 'أدخل صفحة من ١ إلى ٦٠٤';

  @override
  String get khatmaChooseDuration => 'اختر المدة';

  @override
  String khatmaTotalPages(int pages) {
    return 'المجموع: $pages صفحات';
  }

  @override
  String khatmaAssignedPages(int pages) {
    return 'ورد اليوم: $pages';
  }

  @override
  String khatmaConfirmedPages(int pages) {
    return 'المؤكد اليوم: $pages';
  }

  @override
  String khatmaRemainingTodayPages(int pages) {
    return 'المتبقي اليوم: $pages';
  }

  @override
  String get khatmaSaveProgressAction => 'حفظ التقدّم';

  @override
  String get khatmaReturnToQuranAction => 'العودة إلى القرآن';

  @override
  String get khatmaStartAyah => 'آية البداية';

  @override
  String get khatmaEndAyah => 'آية النهاية';

  @override
  String khatmaAyahNumber(int number) {
    return 'آية $number';
  }

  @override
  String get khatmaScheduleByDuration => 'المدة';

  @override
  String get khatmaScheduleByTargetDate => 'تاريخ الإنهاء';

  @override
  String get khatmaChooseTargetDate => 'اختر تاريخ الإنهاء';

  @override
  String get khatmaPreviewPlanAction => 'معاينة الخطة';

  @override
  String get khatmaEditPlanAction => 'تعديل الخطة';

  @override
  String get khatmaEditPlanTitle => 'راجع تغييرات الخطة';

  @override
  String get khatmaEditPlanSubtitle =>
      'عدّل المدة أو تاريخ الإنهاء مع حفظ التقدّم';

  @override
  String get khatmaSavePlanChangesAction => 'حفظ التغييرات';

  @override
  String get khatmaDeletePlanAction => 'حذف الخطة';

  @override
  String get khatmaResetCorruptAction => 'إعادة ضبط الختمة';

  @override
  String get todayPlanTitle => 'خطة اليوم';

  @override
  String get todayPlanMotivationDefault =>
      'القليل كل يوم أسهل حفظًا واستمرارًا.';

  @override
  String get todayPlanMotivationComplete =>
      'اكتملت خطة اليوم. حافظ على هذا النسق بهدوء.';

  @override
  String todayPlanReadPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اقرأ $count صفحات',
      two: 'اقرأ صفحتين',
      one: 'اقرأ صفحة واحدة',
    );
    return '$_temp0';
  }

  @override
  String todayPlanContinueFromPage(int page) {
    return 'تابع من صفحة $page';
  }

  @override
  String get todayPlanShortReadingSession => 'ابدأ بجلسة قراءة قصيرة';

  @override
  String todayPlanListenMinutes(int minutes) {
    return 'استمع لمدة $minutes دقائق';
  }

  @override
  String get todayPlanContinueListening => 'تابع الاستماع';

  @override
  String todayPlanListeningSubtitle(String surahName, String reciterName) {
    return '$surahName · $reciterName';
  }

  @override
  String get todayPlanChooseReciter => 'اختر قارئًا واستمع بهدوء';

  @override
  String get todayPlanMorningAdhkar => 'أذكار الصباح';

  @override
  String get todayPlanMorningAdhkarSubtitle => 'ذكر قصير قبل انشغال اليوم';

  @override
  String get todayPlanTasbeehGoal => 'هدف التسبيح';

  @override
  String todayPlanProgress(int completed, int total, int minutes) {
    return '$completed من $total مكتملة · المتبقي $minutes د';
  }

  @override
  String get todayPlanContinue => 'تابع';

  @override
  String todayPlanStreakDays(int days) {
    return '$days ي';
  }

  @override
  String todayPlanMinutesShort(int minutes) {
    return '$minutesد';
  }

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
  String get continueListening => 'أكمل الاستماع';

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
  String get loading => 'جاري التحميل';

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
  String settingsMemberSince(String date) {
    return 'عضو منذ $date';
  }

  @override
  String get settingsLoginSection => 'تسجيل الدخول';

  @override
  String get settingsSupportSection => 'الدعم';

  @override
  String get whatsNewSettingsTile => 'ما الجديد';

  @override
  String whatsNewTitle(String version) {
    return 'ما الجديد في $version';
  }

  @override
  String whatsNewSemanticsLabel(String version) {
    return 'ما الجديد في الإصدار $version';
  }

  @override
  String get whatsNewGotIt => 'تم';

  @override
  String get settingsAppearance => 'المظهر';

  @override
  String get settingsPlaybackAndStorage => 'التشغيل والتخزين';

  @override
  String get settingsRecitersSection => 'القراء';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeSystem => 'النظام';

  @override
  String get chooseTheme => 'اختر السمة';

  @override
  String get bottomNavHome => 'الرئيسية';

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
  String get bottomNavQibla => 'القبلة';

  @override
  String get bottomNavQuran => 'المصحف';

  @override
  String get bottomNavAthkar => 'الذكر';

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
  String get welcomeToApp => 'مرحباً بك في أنا مسلم';

  @override
  String get signInWithGoogleDescription => 'سجل الدخول بحساب جوجل للمتابعة';

  @override
  String get signingIn => 'جاري تسجيل الدخول...';

  @override
  String get continueWithGoogle => 'تسجيل الدخول باستخدام Google';

  @override
  String get googleSignInNotConfigured =>
      'تسجيل الدخول بجوجل غير مُعد. يرجى الاتصال بالدعم.';

  @override
  String get unableToSignInWithThirdPartyAccount =>
      'تعذر تسجيل الدخول باستخدام حساب طرف ثالث';

  @override
  String get googleSignInNoAccountsOnDevice =>
      'لم يتم العثور على حساب Google على هذا الجهاز. يرجى إضافة حساب Google في إعدادات الجهاز والمحاولة مرة أخرى.';

  @override
  String get googleSignInFallbackTitle => 'تعذّر فتح تسجيل الدخول عبر Google';

  @override
  String get googleSignInFallbackBody =>
      'قد تكون نافذة اختيار حساب Google مخفية على هذا الجهاز. حدّث خدمات Google Play ثم أعد المحاولة. إذا استمرت المشكلة، اطلب من المطوّر تسجيل SHA-1 لهذا الإصدار في Firebase.';

  @override
  String get googleSignInUpdatePlayServices => 'تحديث خدمات Google Play';

  @override
  String get googleSignInTimeout =>
      'انتهت مهلة تسجيل الدخول. يرجى المحاولة مرة أخرى.';

  @override
  String get googleSignInTimeoutUiHidden =>
      'انتهت مهلة تسجيل الدخول. إذا لم تظهر نافذة اختيار الحساب، ارجع وحاول مرة أخرى، أو استخدم الخيارات أدناه.';

  @override
  String get googleSignInUserMismatch =>
      'حساب Google هذا لا يطابق الحساب المسجّل. يرجى المحاولة مرة أخرى.';

  @override
  String get googleSignInCancelled => 'تم إلغاء تسجيل الدخول.';

  @override
  String get networkError => 'يرجى التحقق من اتصالك بالإنترنت';

  @override
  String get serverActionOfflineMessage =>
      'لا يوجد اتصال بالإنترنت. يرجى إعادة الاتصال ثم المحاولة مرة أخرى.';

  @override
  String get authErrorGenericMessage => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get signInWithEmailDescription =>
      'سجّل الدخول ببريدك الإلكتروني وكلمة المرور';

  @override
  String get createAccountDescription =>
      'أنشئ حساباً بالبريد الإلكتروني وكلمة المرور';

  @override
  String get emailAddress => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get signInWithEmail => 'تسجيل الدخول بالبريد';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String registrationStepProgress(int current, int total, String title) {
    return 'الخطوة $current من $total: $title';
  }

  @override
  String get registrationStepAccountTitle => 'الحساب';

  @override
  String get registrationStepAccountDescription =>
      'اختر بريدك الإلكتروني وكلمة المرور';

  @override
  String get registrationStepPersonalTitle => 'البيانات الشخصية';

  @override
  String get registrationStepPersonalDescription => 'أخبرنا عن نفسك';

  @override
  String get registrationStepLearningTitle => 'تعلّم القرآن';

  @override
  String get registrationStepLearningDescription => 'ماذا تريد أن تتعلّم؟';

  @override
  String get registrationStepReviewTitle => 'المراجعة';

  @override
  String get registrationStepReviewDescription => 'راجع بياناتك ثم أنشئ حسابك';

  @override
  String get registrationPreferredLanguageLabel => 'لغة التطبيق المفضّلة';

  @override
  String get registrationDisplayNameRequired => 'أدخل اسمك الكامل';

  @override
  String get registrationGenderRequired => 'اختر الجنس';

  @override
  String get registrationDateOfBirthRequired => 'اختر تاريخ الميلاد';

  @override
  String get registrationCountryRequired => 'اختر الدولة';

  @override
  String get registrationCityRequired => 'اختر المدينة';

  @override
  String get registrationPreferredLanguageRequired => 'اختر اللغة المفضّلة';

  @override
  String get registrationLearningGoalsRequired =>
      'اختر هدف تعلّم واحداً على الأقل';

  @override
  String get registrationProfilePersistenceFailed =>
      'تم إنشاء الحساب لكن حفظ الملف الشخصي فشل. أعد المحاولة أو أكمل ملفك بعد تسجيل الدخول.';

  @override
  String get registrationRetryProfileSave => 'إعادة حفظ الملف الشخصي';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get forgotPasswordDescription =>
      'أدخل بريدك الإلكتروني وسنرسل رابط إعادة التعيين';

  @override
  String get sendResetLink => 'إرسال رابط إعادة التعيين';

  @override
  String get orContinueWith => 'أو تابع باستخدام';

  @override
  String get alreadyHaveAccount => 'لديك حساب؟ سجّل الدخول';

  @override
  String get noAccountYet => 'لا تملك حساباً؟ أنشئ حساباً';

  @override
  String get authInvalidEmail => 'أدخل بريداً إلكترونياً صالحاً';

  @override
  String get authWeakPassword => 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';

  @override
  String get authPasswordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get authUserNotFound => 'لا يوجد حساب بهذا البريد';

  @override
  String get authWrongPassword => 'كلمة المرور غير صحيحة';

  @override
  String get authEmailAlreadyInUse =>
      'يوجد حساب بهذا البريد. سجّل الدخول بدلاً من ذلك.';

  @override
  String get authEmailAlreadyInUseWithGoogle =>
      'هذا البريد مسجّل بحساب Google. سجّل الدخول بـ Google.';

  @override
  String get authAccountExistsWithDifferentCredential =>
      'هذا البريد يستخدم طريقة تسجيل مختلفة. استخدم الطريقة الأصلية.';

  @override
  String get authAccountExistsUseEmailPassword =>
      'هذا البريد مسجّل بكلمة مرور. سجّل الدخول بالبريد.';

  @override
  String get authTooManyRequests => 'محاولات كثيرة. انتظر ثم أعد المحاولة.';

  @override
  String get authOperationNotAllowed =>
      'تسجيل الدخول بالبريد غير مفعّل. تواصل مع الدعم.';

  @override
  String get authUserDisabled => 'تم تعطيل هذا الحساب. تواصل مع الدعم.';

  @override
  String get authInvalidCredential => 'البريد أو كلمة المرور غير صحيحة';

  @override
  String get authResetEmailSent =>
      'إذا وُجد حساب، أُرسل رابط إعادة التعيين إلى بريدك.';

  @override
  String get completeProfilePrompt => 'أكمل ملفك الشخصي لحجز جلسات القرآن';

  @override
  String get downloadLowStorageWarning =>
      'قد لا تكون مساحة التخزين المتاحة كافية لهذا التحميل. حرّر مساحة إذا فشل التحميل.';

  @override
  String get downloadLowStorageBlocked =>
      'لا توجد مساحة تخزين كافية لتحميل كل السور. حرّر مساحة ثم أعد المحاولة.';

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
  String get colorInk => 'فحمي';

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
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountConfirmation =>
      'سيؤدي هذا إلى حذف حسابك في أنا مسلم وبيانات ملفك المتزامنة نهائياً. قد نحتفظ بسجلات مشتريات مجهولة للوقاية من الاحتيال. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get deleteAccountFailed => 'تعذّر حذف حسابك. يرجى المحاولة مرة أخرى.';

  @override
  String get deleteAccountAdminMustUseAdminPanel =>
      'يجب حذف حسابات المسؤولين من لوحة الإدارة.';

  @override
  String get deleteAccountWalletNotEmpty =>
      'يجب أن يكون رصيد محفظتك صفراً قبل حذف حسابك. يرجى استرداد الرصيد أو استخدامه أولاً.';

  @override
  String get deleteAccountActiveBookingsStudent =>
      'لديك حجوزات نشطة كطالب. يرجى إلغاءها أو إكمالها قبل حذف حسابك.';

  @override
  String get deleteAccountActiveBookingsTeacher =>
      'لديك حجوزات نشطة كمعلّم. يرجى إلغاءها أو إكمالها قبل حذف حسابك.';

  @override
  String get deleteAccountAlreadyPending =>
      'طلب حذف الحساب قيد الانتظار بالفعل.';

  @override
  String get deleteAccountServiceUnavailable =>
      'حذف الحساب غير متاح مؤقتاً. يرجى تحديث التطبيق أو المحاولة لاحقاً.';

  @override
  String get deleteAccountNotSignedIn => 'يجب تسجيل الدخول لحذف حسابك.';

  @override
  String get deleteAccountInProgress => 'جارٍ حذف حسابك...';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get requestAccountDeletionWeb => 'طلب حذف الحساب عبر الويب';

  @override
  String get settingsLegalSection => 'قانوني';

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
  String get audioServiceInitFailed =>
      'تعذّر تشغيل الصوت في الخلفية. قد لا يعمل التشغيل حتى إعادة فتح التطبيق.';

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
  String get showRecitersAlphabetIndex => 'إظهار فهرس الحروف';

  @override
  String get showRecitersAlphabetIndexSubtitle =>
      'عرض شريط أ-ي أثناء تصفح القراء';

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
  String get tasbeehTargetHint => 'مثال: 33';

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
  String get tasbeehQuickCountTitle => 'عد سريع';

  @override
  String get tasbeehQuickCountSubtitle => 'عد بدون حفظ — اضغط للبدء';

  @override
  String tasbeehProgressLabel(int current, int target) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat targetNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String targetString = targetNumberFormat.format(target);

    return '$currentString / $targetString';
  }

  @override
  String get tasbeehShowAsList => 'عرض كقائمة';

  @override
  String get tasbeehShowAsGrid => 'عرض كشبكة';

  @override
  String get tasbeehClearAllTitle => 'مسح كل المسبحات المحفوظة؟';

  @override
  String tasbeehClearAllMessage(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'سيؤدي هذا إلى إزالة كل الـ $countString أذكار محفوظة وتذكيراتها. لا يمكن التراجع عن ذلك.';
  }

  @override
  String get tasbeehReminderSheetTitle => 'تذكير يومي';

  @override
  String get tasbeehReminderEnabledLabel => 'تذكير يومي';

  @override
  String get tasbeehReminderEnabledSubtitle =>
      'تلقَّ إشعاراً محلياً في الوقت الذي تختاره';

  @override
  String tasbeehReminderPickTime(String time) {
    return 'وقت التذكير: $time';
  }

  @override
  String get tasbeehReminderAction => 'تذكير';

  @override
  String get tasbeehReminderNotificationBody => 'حان وقت ذكرك';

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
  String get qiblaFinderTitle => 'محدد القبلة';

  @override
  String get qiblaDeviceAngleLabel => 'اتجاه القبلة من الشمال';

  @override
  String qiblaRotatePhoneLeft(int degrees) {
    return 'أدر الهاتف $degrees° إلى اليسار';
  }

  @override
  String qiblaRotatePhoneRight(int degrees) {
    return 'أدر الهاتف $degrees° إلى اليمين';
  }

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
  String quranTranslationAttribution(
    String translationName,
    String sourceName,
  ) {
    return 'الترجمة: $translationName ($sourceName)';
  }

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
  String get quranReader => 'المصحف الشريف';

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
  String get quranHubTitle => 'القرآن';

  @override
  String get quranCatalogSectionTitle => 'القرآن الكريم';

  @override
  String get quranOpenMushaf => 'فتح المصحف';

  @override
  String get quranSwitchToAyahList => 'عرض قائمة الآيات';

  @override
  String get quranSwitchToMushaf => 'عرض المصحف';

  @override
  String get continueReadingQuran => 'متابعة قراءة القرآن';

  @override
  String get surahIndex => 'فهرس السور';

  @override
  String get hijriCalendarTitle => 'التقويم الهجري';

  @override
  String get hijriCalendarOpenLabel => 'فتح التقويم الهجري';

  @override
  String get hijriCalendarPreviousMonth => 'الشهر السابق';

  @override
  String get hijriCalendarNextMonth => 'الشهر التالي';

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
  String get sharedViaTilawa => 'تمت المشاركة عبر أنا مسلم';

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
  String get adhanSound1 => 'الصوت ١';

  @override
  String get adhanSound2 => 'الصوت ٢';

  @override
  String get adhanSound3 => 'الصوت ٣';

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
      'في هذا الجهاز، فعّل أيضاً التشغيل التلقائي لتطبيق أنا مسلم من إعدادات الهاتف حتى لا تتوقف التذكيرات في الخلفية.';

  @override
  String get prayerAlertsPermissionLocationTitle => 'الموقع';

  @override
  String get prayerAlertsPermissionLocationBody =>
      'اسمح بالوصول إلى الموقع لحساب أوقات الصلاة حسب مكانك. تُحدَّث الأوقات تلقائياً عند السفر.';

  @override
  String get prayerAlertsPermissionNotificationsTitle => 'السماح بالإشعارات';

  @override
  String get prayerAlertsPermissionNotificationsBody =>
      'للتأكد من عدم تفويت أي وقت للصلاة، يُرجى السماح بالإشعارات. ستُذكّرك الإشعارات عند حلول وقت كل صلاة.';

  @override
  String get prayerAlertsPermissionExactAlarmTitle => 'التنبيهات والتذكيرات';

  @override
  String get prayerAlertsPermissionExactAlarmBody =>
      'اسمح بإذن التنبيهات والتذكيرات حتى يعمل الأذان وتنبيهات الصلاة في وقتها، حتى عندما يكون الهاتف في وضع السكون أو الشاشة مغلقة.';

  @override
  String get prayerAlertsPermissionBatteryTitle => 'تحسين البطارية';

  @override
  String get prayerAlertsPermissionBatteryBody =>
      'استثنِ أنا مسلم من تحسين البطارية حتى لا تتأخر تذكيرات الصلاة ليلاً.';

  @override
  String get prayerAlertsPermissionOemAutostartTitle => 'العمل في الخلفية';

  @override
  String get prayerAlertsPermissionOemAutostartBody =>
      'في هذا الجهاز، فعّل التشغيل التلقائي لتطبيق أنا مسلم من إعدادات الهاتف حتى لا تتوقف التذكيرات في الخلفية.';

  @override
  String get prayerAlertsPermissionAllow => 'السماح';

  @override
  String get prayerAlertsPermissionSkip => 'تخطي';

  @override
  String get prayerAlertsPermissionContinue => 'متابعة';

  @override
  String get prayerAlertsPermissionSetupRequired =>
      'بعض الأذونات مطلوبة لتذكيرات الصلاة والأذان بشكل موثوق.';

  @override
  String get prayerAlertsPermissionSetupAction => 'إعداد الأذونات';

  @override
  String prayerNotificationBody(String prayerName) {
    return 'حان وقت $prayerName';
  }

  @override
  String prayerNotificationTitleWithLocation(
    String prayerName,
    String locationName,
  ) {
    return '$prayerName · $locationName';
  }

  @override
  String prayerNotificationBodyWithLocation(
    String prayerName,
    String locationName,
  ) {
    return 'حان وقت $prayerName في $locationName';
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
  String get adhanIsPlaying => 'الأذان قيد التشغيل…';

  @override
  String adhanPlayingNotificationBodyWithLocation(String locationName) {
    return 'الأذان قيد التشغيل في $locationName';
  }

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
  String get homeMoreOptionsSubtitle => 'مكتبتك وخيارات أخرى';

  @override
  String get supportTilawa => 'ادعم أنا مسلم';

  @override
  String get rateTilawa => 'قيّم أنا مسلم';

  @override
  String get rateTilawaSubtitle => 'شاركنا رأيك في متجر التطبيقات.';

  @override
  String get reportBugSettingsTileTitle => 'الإبلاغ عن خطأ';

  @override
  String get reportBugSettingsTileSubtitle =>
      'أخبرنا بما حدث لنساعدك في إصلاحه.';

  @override
  String get reportBugTitle => 'الإبلاغ عن خطأ';

  @override
  String get reportBugFormTitle => 'الإبلاغ عن خطأ';

  @override
  String get reportBugMessageLabel => 'الوصف';

  @override
  String get reportBugMessagePlaceholder => 'ماذا حدث؟ ماذا كنت تتوقع؟';

  @override
  String get reportBugNameLabel => 'الاسم';

  @override
  String get reportBugNamePlaceholder => 'اسمك';

  @override
  String get reportBugEmailLabel => 'البريد الإلكتروني';

  @override
  String get reportBugEmailPlaceholder => 'your.email@example.com';

  @override
  String get reportBugSubmitButton => 'إرسال البلاغ';

  @override
  String get reportBugCancelButton => 'إلغاء';

  @override
  String get reportBugSuccessMessage => 'شكرًا على بلاغك.';

  @override
  String get reportBugRequiredLabel => ' (مطلوب)';

  @override
  String get reportBugValidationError => 'هذا الحقل مطلوب.';

  @override
  String get reportBugCaptureScreenshot => 'إرفاق لقطة شاشة';

  @override
  String get reportBugRemoveScreenshot => 'إزالة لقطة الشاشة';

  @override
  String get reportBugPreviewScreenshot => 'معاينة لقطة الشاشة';

  @override
  String get reportBugScreenshotPreviewTitle => 'لقطة الشاشة';

  @override
  String get reportBugCaptureScreenshotFromAnotherScreen =>
      'إرفاق من شاشة أخرى';

  @override
  String get reportBugScreenshotCaptureHint =>
      'انتقل إلى الشاشة المطلوبة، ثم اضغط التقاط.';

  @override
  String get reportBugScreenshotCaptureNow => 'التقاط';

  @override
  String get reportBugScreenshotCaptureCancel => 'العودة إلى البلاغ';

  @override
  String get reportBugScreenshotCaptureFailed =>
      'تعذّر التقاط لقطة الشاشة. يمكنك إرسال البلاغ بدونها.';

  @override
  String get shareTilawa => 'شارك أنا مسلم';

  @override
  String shareTilawaMessage(String appName, String storeUrl) {
    return 'جرّب $appName:\n$storeUrl';
  }

  @override
  String get shareTilawaFailed => 'تعذر فتح نافذة المشاركة. حاول مرة أخرى.';

  @override
  String get supportIntroLine => 'مشاركتك تساعدنا على استمرار أنا مسلم.';

  @override
  String get supportTilawaSubtitle => 'مشاركتك تساعدنا على استمرار أنا مسلم.';

  @override
  String get supportMissionBody => 'مشاركتك تساعدنا على استمرار أنا مسلم.';

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
      'يتم الدفع عبر Google Play. أنا مسلم لا يحتفظ ببيانات بطاقتك.';

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
  String get supportSettingsGroupTitle => 'ادعم أنا مسلم';

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
  String get purchaseAppCheckFailedDebug =>
      'تعذّر تأكيد الدعم لأن App Check غير مُعدّ لهذا الإصدار. في Firebase Console، افتح App Check وسجّل رمز تصحيح لهذا الجهاز، ثم أعد المحاولة.';

  @override
  String get purchaseAppCheckFailedRelease =>
      'تعذّر تأكيد دعمك لأن هذا الجهاز لم يُتحقق منه. حدّث التطبيق وأعد المحاولة لاحقًا.';

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
  String get a11ySplashLoading => 'أنا مسلم، جارٍ التحميل';

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

  @override
  String get adhanDebugTestTitle => 'اختبار الأذان بعد 10 ثوانٍ';

  @override
  String get adhanDebugTestSubtitle =>
      'يطلب إذن الإشعارات ثم يجدول منبه الأذان الأصلي.';

  @override
  String get adhanDebugScheduled => 'تمت جدولة اختبار الأذان بعد 10 ثوانٍ';

  @override
  String get adhanDebugNativeInexactScheduled =>
      'تمت جدولة اختبار الأذان أصليًا بتوقيت تقريبي. فعّل التنبيهات والتذكيرات للتوقيت الدقيق.';

  @override
  String get adhanDebugFallbackScheduled =>
      'تمت جدولة اختبار الأذان بالمسار الاحتياطي. فعّل التنبيهات والتذكيرات للتشغيل الأصلي.';

  @override
  String get adhanDebugPermissionMissing =>
      'يلزم إذن الإشعارات قبل جدولة اختبار الأذان';

  @override
  String get adhanDebugFailed => 'تعذّرت جدولة اختبار الأذان';

  @override
  String get notificationDebugLabTitle => 'اختبار الإشعارات';

  @override
  String get notificationDebugSectionLocal => 'اختبارات الإشعار المحلي';

  @override
  String get notificationDebugSectionLaunch => 'محاكاة الإطلاق';

  @override
  String get notificationDebugSectionDedup => 'فحص حالة منع التكرار';

  @override
  String get notificationDebugSectionChecklist => 'قائمة التحقق اليدوية';

  @override
  String get notificationDebugSectionLogs => 'سجلات التصحيح';

  @override
  String get notificationDebugActionId => 'معرّف الإشعار';

  @override
  String get notificationDebugActionPayload => 'الحمولة';

  @override
  String get notificationDebugActionRoute => 'المسار المتوقع';

  @override
  String get notificationDebugActionBehavior => 'السلوك المتوقع';

  @override
  String get notificationDebugActionMechanism => 'الآلية';

  @override
  String get notificationDebugRefreshState => 'تحديث الحالة';

  @override
  String get notificationDebugClearDedup => 'مسح منع تكرار الإشعار';

  @override
  String get notificationDebugClearAthkarDedup => 'مسح منع تكرار أذكار (دافئ)';

  @override
  String get notificationDebugClearAll => 'مسح كل حالة التصحيح';

  @override
  String get notificationDebugClearLogs => 'مسح السجلات';

  @override
  String get notificationDebugConfirmSchedule => 'جدولة إشعار تصحيح آخر؟';

  @override
  String get notificationDebugMechanismReal => 'إشعار محلي حقيقي';

  @override
  String get notificationDebugMechanismDispatcher => 'محاكاة الموزّع';

  @override
  String get notificationDebugMechanismBootstrap => 'فحص إطلاق Bootstrap';

  @override
  String get notificationDebugMechanismDedup => 'حفظ منع التكرار فقط';

  @override
  String get notificationDebugMechanismClearPid => 'مسح نطاق pid';

  @override
  String get notificationDebugBehaviorScheduleAthkar =>
      'يعرض إشعار أذكار تصحيح بعد تأخير قصير';

  @override
  String get notificationDebugBehaviorShowNow => 'ينشر إشعار تصحيح فورًا';

  @override
  String get notificationDebugBehaviorNativePayloadOnly =>
      'يحاكي نقرة صلاة أصلية بحمولة فقط (بدون معرّف)';

  @override
  String get notificationDebugBehaviorInvalidPayload =>
      'يجب ألا ينتقل إلى الأذكار';

  @override
  String get notificationDebugBehaviorEmptyPayload =>
      'يجب ألا ينتقل (حمولة فارغة)';

  @override
  String get notificationDebugBehaviorPayloadOnlyNoId =>
      'التوجيه عبر توقيع الحمولة فقط';

  @override
  String get notificationDebugBehaviorDedupSameSig =>
      'النقرة الأولى تنتقل؛ نفس pid + التوقيع يُمنع التكرار';

  @override
  String get notificationDebugBehaviorFreshDifferentPayload =>
      'يُعامل كجديد عند تغيّر توقيع الحمولة';

  @override
  String get notificationDebugBehaviorSharedPayloadSig =>
      'توقيع الحمولة يمنع التكرار حتى لو اختلف المعرّف';

  @override
  String get notificationDebugBehaviorSimulateTap =>
      'يتوجّه عبر مسارات الإنتاج (الموزّع / Bootstrap)';

  @override
  String get notificationDebugBehaviorInvalidLaunch =>
      'حمولة غير صالحة لا يجب أن تضبط مسار أذكار';

  @override
  String get notificationDebugBehaviorMarkProcessed =>
      'يحفظ منع التكرار دون تنقل';

  @override
  String get notificationDebugBehaviorClearPidScope =>
      'يمسح مفتاح pid لمحاكاة نطاق عملية جديدة';

  @override
  String get notificationDebugFieldCurrentPid => 'معرّف العملية الحالي';

  @override
  String get notificationDebugFieldStoredPid => 'pid المخزّن (_last_notif_pid)';

  @override
  String get notificationDebugFieldStoredId =>
      'المعرّف المخزّن (_last_notif_id)';

  @override
  String get notificationDebugFieldStoredSig =>
      'التوقيع المخزّن (_last_notif_payload_sig)';

  @override
  String get notificationDebugFieldLastProcessedId =>
      'AppRouter.lastProcessedNotificationId';

  @override
  String get notificationDebugFieldPendingRoute => 'pendingColdStartLocation';

  @override
  String get notificationDebugFieldPendingExtra => 'pendingColdStartExtra';

  @override
  String get notificationDebugFieldAthkarPayload =>
      'last_handled_notification_payload';

  @override
  String get notificationDebugFieldAthkarTimestamp =>
      'last_handled_notification_timestamp';

  @override
  String get notificationDebugFieldPreviewSig => 'معاينة التوقيع';

  @override
  String get notificationDebugFieldProcessedPreview => 'المعاينة مُعالَجة';

  @override
  String get notificationDebugChecklistAthkarTitle => 'أ. إشعار الأذكار';

  @override
  String get notificationDebugChecklistAthkarTap =>
      'نقر إشعار الأذكار → يفتح الأذكار مرة واحدة';

  @override
  String get notificationDebugChecklistAthkarRestart =>
      'إعادة تشغيل سريعة → لا يفتح الأذكار مجددًا';

  @override
  String get notificationDebugChecklistPrayerTitle =>
      'ب. إشعار صلاة (حمولة فقط)';

  @override
  String get notificationDebugChecklistPrayerTap =>
      'نقر إشعار الصلاة → يفتح مسار الصلاة مرة واحدة';

  @override
  String get notificationDebugChecklistPrayerRestart =>
      'إعادة تشغيل سريعة → لا يُعاد التشغيل';

  @override
  String get notificationDebugChecklistInvalidTitle => 'ج. حمولة غير صالحة';

  @override
  String get notificationDebugChecklistInvalidBody =>
      'حمولة غير صالحة → لا ترجع للأذكار';

  @override
  String get notificationDebugChecklistSettingsTitle => 'د. حمولة الإعدادات';

  @override
  String get notificationDebugChecklistSettingsBody =>
      'حمولة الإعدادات → تفتح الإعدادات وليس الأذكار';

  @override
  String get notificationDebugChecklistSameSigTitle =>
      'هـ. نفس المعرّف + نفس الحمولة';

  @override
  String get notificationDebugChecklistSameSigTap =>
      'النقرة الأولى → تنقل مرة واحدة';

  @override
  String get notificationDebugChecklistSameSigRestart =>
      'إعادة تشغيل سريعة / نفس العملية → مُمنوع';

  @override
  String get notificationDebugChecklistDiffPayloadTitle =>
      'و. نفس المعرّف + حمولة مختلفة';

  @override
  String get notificationDebugChecklistDiffPayloadBody => 'يُعامل كإطلاق جديد';

  @override
  String get notificationDebugChecklistDiffIdTitle =>
      'ز. معرّف مختلف + نفس الحمولة';

  @override
  String get notificationDebugChecklistDiffIdBody =>
      'توقيع الحمولة أولًا → النقرة الثانية مُمنوعة في نفس pid';

  @override
  String get notificationDebugChecklistKillTitle => 'ح. إنهاء العملية بالكامل';

  @override
  String get notificationDebugChecklistKillSteps =>
      'أغلق التطبيق من المهام الأخيرة → انقر إشعارًا جديدًا → يجب أن يعمل التوجيه البارد';

  @override
  String get notificationDebugLogsEmpty => 'لا أحداث تصحيح بعد';

  @override
  String get inAppUpdateFlexibleRestartMessage =>
      'تم تنزيل التحديث. أعد التشغيل عندما تكون مستعدًا للتثبيت.';

  @override
  String get inAppUpdateOptionalMessage => 'يتوفر إصدار جديد من أنا مسلم.';

  @override
  String get inAppUpdateRequiredMessage =>
      'يلزم التحديث لمتابعة استخدام أنا مسلم.';

  @override
  String get inAppUpdateRestartAction => 'إعادة التشغيل';

  @override
  String get inAppUpdateUpdateAction => 'تحديث';

  @override
  String recitationPracticeTitle(int surah, int ayah) {
    return 'تدريب $surah:$ayah';
  }

  @override
  String get recitationPracticeStart => 'ابدأ التلاوة';

  @override
  String get recitationPracticeStop => 'إيقاف';

  @override
  String recitationPracticeScore(int percent) {
    return 'التطابق $percent٪';
  }

  @override
  String get recitationPracticeNextAyah => 'الآية التالية';

  @override
  String get recitationPracticeTooltip => 'تدريب التلاوة';

  @override
  String recitationPracticeSessionProgress(int current, int total) {
    return 'الآية $current من $total';
  }

  @override
  String get recitationPracticeListening => 'يستمع…';

  @override
  String get recitationPracticeEndSession => 'إنهاء الجلسة';

  @override
  String get recitationPracticeSessionComplete => 'اكتملت الصفحة';

  @override
  String recitationPracticeCompletedCount(int count, int total) {
    return '$count من $total ناجحة';
  }

  @override
  String get authSignedInElsewhereTitle => 'تم تسجيل خروجك من جهاز آخر';

  @override
  String get authSignedInElsewhereBody =>
      'تم تسجيل خروجك لأن الحساب تم استخدامه على جهاز آخر.';

  @override
  String get authSignedInElsewhereAction => 'تسجيل الدخول مجدداً';

  @override
  String get authDeviceRegistrationFailed =>
      'تعذّر إكمال تسجيل الدخول. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get authAppCheckFailedDebug =>
      'تعذّر تسجيل الدخول لأن App Check غير مُعدّ لهذا الإصدار. في Firebase Console، افتح App Check وسجّل رمز تصحيح لهذا الجهاز، ثم أعد المحاولة.';

  @override
  String get authAppCheckFailedRelease =>
      'تعذّر إكمال تسجيل الدخول لأن هذا الجهاز لم يُتحقق منه. حدّث التطبيق وأعد المحاولة لاحقًا.';

  @override
  String get authSessionVerifying => 'جارٍ التحقق من جلستك…';

  @override
  String get manageDevicesTitle => 'الأجهزة';

  @override
  String get manageDevicesSubtitle =>
      'أنت مُسجَّل الدخول على هذه الأجهزة. سجّل الخروج من أي جهاز لا تعرفه.';

  @override
  String get manageDevicesThisDevice => 'هذا الجهاز';

  @override
  String get manageDevicesSignedOutBadge => 'تم تسجيل الخروج';

  @override
  String get manageDevicesSignOutDevice => 'تسجيل الخروج';

  @override
  String get manageDevicesSignOutOthers =>
      'تسجيل الخروج من جميع الأجهزة الأخرى';

  @override
  String get manageDevicesSignOutOthersConfirm =>
      'تسجيل الخروج من كل الأجهزة عدا هذا الجهاز؟ ستبقى مُسجَّلاً هنا.';

  @override
  String get manageDevicesEmpty => 'لا توجد أجهزة أخرى مُسجَّلة الدخول.';

  @override
  String get manageDevicesError => 'تعذّر تحميل أجهزتك.';

  @override
  String get manageDevicesSignOutFailed =>
      'تعذّر تسجيل الخروج من هذا الجهاز. حاول مرة أخرى.';

  @override
  String manageDevicesLastActive(String when) {
    return 'آخر نشاط $when';
  }

  @override
  String get manageDevicesSignedOutMessage => 'تم تسجيل الخروج من هذا الجهاز.';

  @override
  String get settingsManageDevicesTile => 'الأجهزة';

  @override
  String get settingsSecuritySection => 'الأمان';

  @override
  String get wirdWidgetTitle => 'وِرد اليوم';

  @override
  String get wirdWidgetNoPlanSubtitle => 'ابدأ خطة هادئة لقراءة القرآن';

  @override
  String wirdWidgetProgressSubtitle(
    String completed,
    String assigned,
    String remaining,
  ) {
    return 'أُنجز $completed من $assigned صفحة · المتبقي $remaining';
  }

  @override
  String get wirdWidgetDayCompletedSubtitle => 'اكتمل وِرد اليوم';

  @override
  String get wirdWidgetPlanCompletedSubtitle => 'اكتملت الختمة';

  @override
  String get settingsAdminUserBadge => 'مستخدم إداري';

  @override
  String get dailyGuidanceTitle => 'رسالة اليوم';

  @override
  String get dailyGuidanceEmpty => 'لا توجد رسالة متاحة اليوم.';

  @override
  String get dailyGuidanceError => 'تعذّر تحميل رسالة اليوم. حاول مرة أخرى.';

  @override
  String get dailyGuidanceEnableNotifications => 'تذكير يومي';

  @override
  String get dailyGuidanceNotificationSubtitle =>
      'تصلك آية أو حديث كل يوم في الوقت الذي تختاره';

  @override
  String get dailyGuidanceSettingsSection => 'نفحات إيمانية';

  @override
  String get dailyGuidanceSettings => 'رسالة اليوم';

  @override
  String get dailyGuidanceSettingsSubtitle => 'آية أو حديث كل يوم';

  @override
  String get dailyGuidanceNotificationTitle => 'رسالة اليوم 🌿';

  @override
  String get dailyGuidanceNotificationBody => 'افتح لقراءة رسالة اليوم';

  @override
  String get dailyGuidanceTypeQuran => 'آية قرآنية';

  @override
  String get dailyGuidanceTypeHadith => 'حديث نبوي';

  @override
  String dailyGuidanceQuranSource(String surahName, int ayahNumber) {
    return 'سورة $surahName، آية $ayahNumber';
  }

  @override
  String dailyGuidanceHadithSource(String collection, String referenceNumber) {
    return '$collection، حديث رقم $referenceNumber';
  }
}
