// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'quran_sessions_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class QuranSessionsLocalizationsAr extends QuranSessionsLocalizations {
  QuranSessionsLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get errorNetwork => 'لا يوجد اتصال بالإنترنت.';

  @override
  String get offlineConnectionRequired => 'يلزم اتصال بالإنترنت.';

  @override
  String get errorTimeout => 'انتهت مهلة الطلب. يرجى المحاولة مجدداً.';

  @override
  String get errorSessionExpired => 'انتهت الجلسة. يرجى تسجيل الدخول مجدداً.';

  @override
  String get errorForbidden => 'ليس لديك صلاحية لتنفيذ هذا الإجراء.';

  @override
  String get errorServer => 'حدث خطأ في الخادم. يرجى المحاولة لاحقاً.';

  @override
  String get unauthorized => 'غير مخوّل للقيام بهذا الإجراء.';

  @override
  String notFound(Object resource) {
    return '$resource غير موجود.';
  }

  @override
  String get sessionDetailNotFound =>
      'تعذر العثور على هذه الجلسة. ربما تم إلغاؤها أو حذفها.';

  @override
  String validationError(Object code, Object field) {
    return 'خطأ في التحقق: $field ($code).';
  }

  @override
  String get slotUnavailable =>
      'هذا الموعد لم يعد متاحاً. يرجى اختيار موعد آخر.';

  @override
  String get bookingConflict => 'لديك جلسة أخرى في نفس الوقت.';

  @override
  String get profileIncompletePrefix => 'ملفك الشخصي غير مكتمل.';

  @override
  String profileIncompleteFields(Object fields) {
    return 'المعلومات المطلوبة: $fields.';
  }

  @override
  String get gender_male => 'ذكر';

  @override
  String get gender_female => 'أنثى';

  @override
  String get gender_male_students => 'الذكور';

  @override
  String get gender_female_students => 'الإناث';

  @override
  String get ageNotAllowedChild => 'هذا المعلم لا يقبل الطلاب الأطفال.';

  @override
  String get ageNotAllowedOther => 'فئتك العمرية غير مقبولة لدى هذا المعلم.';

  @override
  String get teacherNotVerified =>
      'لم يتم توثيق هذا المعلم بعد ولا يمكن حجز جلسة معه.';

  @override
  String accountBlockedWithReason(Object reason) {
    return 'حسابك موقوف بسبب: $reason.';
  }

  @override
  String get accountBlocked => 'حسابك موقوف. يرجى التواصل مع الدعم.';

  @override
  String get sessionRevisionPracticeUpcomingTitle => 'استعد لجلستك';

  @override
  String get sessionRevisionPracticeCompletedTitle => 'تابع مراجعتك';

  @override
  String sessionRevisionPracticeBody(int surahNumber) {
    return 'تدرّب على سورة $surahNumber في قارئ القرآن في تلاوة قبل أو بعد جلستك.';
  }

  @override
  String get sessionRevisionPracticeAction => 'التدرّب في قارئ القرآن';

  @override
  String get teacherCredentialsSectionTitle => 'الشهادات والإجازات';

  @override
  String teacherCredentialsSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شهادات',
      one: 'شهادة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get teacherCredentialsDisclaimer =>
      'الشهادات مقدَّمة من المعلّم. البنود الموثّقة راجعتها تلاوة؛ غيرها مذكورة من المعلّم.';

  @override
  String get teacherCredentialVerifiedBadge => 'موثّقة من تلاوة';

  @override
  String policyViolation(Object detail, Object policy) {
    return 'تم رفض الحجز لمخالفة السياسة \"$policy\": $detail.';
  }

  @override
  String get marketNotEnabledWithCity =>
      'خدمة الجلسات غير متاحة في مدينتك حالياً. جرّب مدينة أخرى.';

  @override
  String get marketNotEnabled => 'خدمة الجلسات غير متاحة في دولتك حالياً.';

  @override
  String get marketCatalogEmpty =>
      'خيارات الدولة والمدينة غير متاحة حالياً. يُرجى المحاولة لاحقاً أو التواصل مع الدعم.';

  @override
  String get teacherNotInMarket =>
      'هذا المعلم غير متاح في منطقتك. يرجى اختيار معلم آخر.';

  @override
  String get dateOfBirthRequired => 'تاريخ الميلاد مطلوب.';

  @override
  String get futureDateOfBirth => 'لا يمكن اختيار تاريخ ميلاد في المستقبل.';

  @override
  String get dateOfBirthTooRecent =>
      'العمر غير مناسب لاستخدام هذه الميزة حاليًا.';

  @override
  String get invalidDateOfBirth =>
      'تاريخ الميلاد غير صالح. يرجى إدخال تاريخ صحيح.';

  @override
  String get teacherApplicationNotFound => 'لم يتم العثور على طلب تسجيل كمعلم.';

  @override
  String get teacherApplicationAlreadyPending =>
      'لديك طلب معلم قيد المراجعة بالفعل.';

  @override
  String get teacherApplicationRejected =>
      'تم رفض طلبك. يمكنك إعادة التقديم بعد انتهاء فترة الانتظار.';

  @override
  String get teacherApplicationSuspended => 'حسابك كمعلم موقوف مؤقتاً.';

  @override
  String get teacherApplicationRevoked => 'تم إلغاء حسابك كمعلم بشكل نهائي.';

  @override
  String get teacherPhoneRequired =>
      'رقم الهاتف مطلوب لإتمام طلب التسجيل كمعلم.';

  @override
  String get invalidTeacherPhone =>
      'رقم الهاتف غير صحيح. يرجى إدخال رقم بصيغة دولية صحيحة.';

  @override
  String get phoneCountryMismatch => 'رقم الهاتف لا يطابق الدولة المختارة.';

  @override
  String get invalidPhoneForSelectedCountry =>
      'رقم الهاتف ينتهك قواعد الدولة المختارة.';

  @override
  String teacherApplicationIncomplete(Object reason) {
    return 'طلب التسجيل غير مكتمل: $reason';
  }

  @override
  String reapplicationTooSoon(Object date) {
    return 'لا يمكنك إعادة التقديم قبل $date.';
  }

  @override
  String get teacherProfileNotApproved => 'لم تتم الموافقة على ملف المعلم بعد.';

  @override
  String get teacherProfileNotActive => 'ملف المعلم غير نشط حالياً.';

  @override
  String get paymentDeclined => 'تم رفض الدفع. يرجى استخدام طريقة دفع أخرى.';

  @override
  String get paymentCancelled => 'تم إلغاء عملية الدفع.';

  @override
  String get paymentProviderFailure =>
      'تعذّرت معالجة الدفع. يرجى المحاولة مجدداً.';

  @override
  String get cacheFailure => 'تعذّرت قراءة البيانات المحلية.';

  @override
  String get unknownFailure => 'حدث خطأ غير متوقع.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get profileCompletionTitle => 'إكمال الملف الشخصي';

  @override
  String get profileCompletionSavedSuccess => 'تم حفظ ملفك الشخصي بنجاح';

  @override
  String get profileCompletionSaving => 'جارٍ حفظ البيانات…';

  @override
  String get profileCompletionHeadline => 'أخبرنا عن نفسك';

  @override
  String get profileCompletionSubtitle =>
      'نحتاج إلى هذه المعلومات لمطابقتك مع المعلم المناسب وعرض الأسعار الصحيحة لمنطقتك.';

  @override
  String get profileCompletionLearnQuranSubtitle =>
      'نحتاج بعض التفاصيل لإعداد حجز جلسة القرآن الخاصة بك.';

  @override
  String get profileFieldGender => 'الجنس';

  @override
  String get profileFieldDateOfBirth => 'تاريخ الميلاد';

  @override
  String get profileFieldCountry => 'الدولة';

  @override
  String get profileFieldCity => 'المدينة';

  @override
  String get profileFieldLearningGoals => 'أهداف التعلّم';

  @override
  String get profileLearningGoalsHelper =>
      'اختياري — يساعدنا على اقتراح المعلم المناسب لك.';

  @override
  String get profileFieldDisplayName => 'الاسم الكامل';

  @override
  String get profileCompletionSaveAndContinue => 'حفظ والمتابعة';

  @override
  String get profileCompletionSelectDateOfBirth => 'اختر تاريخ الميلاد';

  @override
  String get profileCompletionSelectCountry => 'اختر الدولة';

  @override
  String get profileCompletionSelectCity => 'اختر المدينة';

  @override
  String get profileCompletionSelectCountryFirst => 'اختر الدولة أولاً';

  @override
  String get profileCompletionLoadingCities => 'جاري تحميل المدن…';

  @override
  String get profileGenderRequired => 'الجنس مطلوب.';

  @override
  String get profileCountryRequired => 'الدولة مطلوبة.';

  @override
  String get profileCityRequired => 'المدينة مطلوبة.';

  @override
  String get quranSessionsHomeTitle => 'تعلّم القرآن مع محفظك';

  @override
  String get quranSessionsHomeAppBarTitle => 'المحفظون';

  @override
  String get mySessionsTitle => 'جلساتي';

  @override
  String get noTeachersAvailableYet => 'لا يوجد معلمون متاحون بعد';

  @override
  String get seeAllTeachers => 'عرض جميع المعلمين ←';

  @override
  String get becomeTeacherCardTitle => 'أريد أن أصبح محفظًا';

  @override
  String get becomeTeacherCardSubtitle =>
      'انضم إلى نخبة المعلمين المعتمدين على MeMuslim';

  @override
  String get teacherListAppBarTitle => 'المحفظون';

  @override
  String get teacherListTitle => 'تعلّم القرآن مع محفظك';

  @override
  String get teacherListSubtitle =>
      'اختر المحفظ المناسب وابدأ رحلتك في تحسين التلاوة';

  @override
  String get teacherSearchHint => 'ابحث عن المحفظ بالاسم';

  @override
  String noTeachersForSearchQuery(String query) {
    return 'لا يوجد محفظون يطابقون \"$query\"';
  }

  @override
  String get teacherNewRating => 'جديد';

  @override
  String get teacherFilterAll => 'الكل';

  @override
  String get teacherFilterFree => 'مجاني';

  @override
  String get teacherFilterPaid => 'مدفوع';

  @override
  String get teacherFilterBudget => 'اقتصادي';

  @override
  String teacherFilterUnderPrice(String amount) {
    return 'أقل من $amount';
  }

  @override
  String get teacherFilterAvailableToday => 'متاح اليوم';

  @override
  String get teacherBookAction => 'احجز';

  @override
  String get viewTeacherProfile => 'عرض الملف';

  @override
  String get teacherAvailabilityToday => 'متاح اليوم';

  @override
  String get teacherAvailabilityTomorrow => 'أقرب موعد غدًا';

  @override
  String teacherAvailabilityNextAt(String when) {
    return 'أقرب موعد: $when';
  }

  @override
  String get teacherAvailabilityNoSlots => 'لا توجد مواعيد';

  @override
  String get teacherAvailabilityUnavailable => 'غير متاح حاليًا';

  @override
  String get joinSessionNow => 'انضم الآن';

  @override
  String sessionsSummaryUpcoming(int count) {
    return 'القادمة: $count';
  }

  @override
  String sessionsSummaryPast(int count) {
    return 'السابقة: $count';
  }

  @override
  String sessionsSummaryNextSession(String when) {
    return 'أقرب حصة: $when';
  }

  @override
  String get sessionsTabUpcoming => 'القادمة';

  @override
  String get sessionsTabPending => 'قيد الانتظار';

  @override
  String get sessionsTabPast => 'السابقة';

  @override
  String get sessionsTabCancelled => 'الملغاة';

  @override
  String get noPendingSessions => 'لا توجد جلسات قيد الانتظار';

  @override
  String get bookAgainAction => 'احجز مرة أخرى';

  @override
  String get sessionStatusStartingSoon => 'تبدأ قريبًا';

  @override
  String sessionStartsInMinutes(int minutes) {
    return 'يبدأ بعد $minutes د';
  }

  @override
  String get noTeachersForAvailabilityFilter =>
      'لا يوجد معلمون متاحون اليوم حالياً';

  @override
  String noTeachersForSpecialization(String specialization) {
    return 'لم يتم العثور على معلمين لـ \"$specialization\"';
  }

  @override
  String noTeachersForLanguage(String language) {
    return 'لم يتم العثور على معلمين للغة \"$language\"';
  }

  @override
  String get clearTeacherFilters => 'مسح عوامل التصفية';

  @override
  String get noTeachersAvailableRightNow => 'لا يوجد معلمون متاحون حالياً';

  @override
  String get bookSessionTitle => 'احجز جلسة';

  @override
  String get bookingConfirmed => 'تم تأكيد الحجز!';

  @override
  String get checkingEligibility => 'جارٍ التحقق من أهليتك…';

  @override
  String get confirmingBooking => 'جارٍ تأكيد الحجز…';

  @override
  String get selectSlot => 'اختر موعداً';

  @override
  String get sessionType => 'نوع الجلسة';

  @override
  String get confirmBooking => 'تأكيد الحجز';

  @override
  String get callTypeExternalMeeting => 'رابط خارجي';

  @override
  String get callTypeVoice => 'صوتي';

  @override
  String get callTypeVideo => 'مرئي';

  @override
  String get sessionModeVoiceBetaNote =>
      'الجلسات الصوتية تستخدم الاتصال داخل التطبيق عندما يدعمها محفظك وجهازك.';

  @override
  String get sessionModeVideoBetaNote =>
      'جلسات الفيديو تستخدم الاتصال داخل التطبيق عندما يدعمها محفظك وجهازك.';

  @override
  String bookingVoiceVideoProviderNote(String provider) {
    return 'المكالمات داخل التطبيق تستخدم $provider.';
  }

  @override
  String get sessionModeVoiceDisabled =>
      'الجلسات الصوتية غير متاحة بعد. اختر الرابط الخارجي.';

  @override
  String get sessionModeVideoDisabled =>
      'الجلسات المرئية غير متاحة بعد. اختر الرابط الخارجي.';

  @override
  String get sessionModeExternalDisabled =>
      'لم يضف المعلم رابط الاجتماع بعد. اختر الصوت أو الفيديو.';

  @override
  String get meetingLinkUnavailable =>
      'لم يُعدّ المعلم رابط اجتماع للجلسات الخارجية بعد. اختر الصوت أو الفيديو، أو حاول لاحقًا.';

  @override
  String get callProviderUnavailable =>
      'لا يمكن الانضمام إلى هذه الجلسة من التطبيق حاليًا.';

  @override
  String get callProviderAgoraNotConfigured =>
      'مكالمات Agora داخل التطبيق غير مفعّلة في هذا الإصدار. أعد البناء بإعدادات Staging Agora (TILAWA_DISTRIBUTION=staging وTILAWA_LAUNCH_AGORA_APP_ID)، أو استخدم ملف التشغيل MeMuslim (Staging Agora).';

  @override
  String rtcPermissionDenied(String permission) {
    return 'يلزم الوصول إلى الميكروفون أو الكاميرا للانضمام. فعّل $permission من الإعدادات ثم أعد المحاولة.';
  }

  @override
  String get rtcCallJoinFailed =>
      'تعذّر الاتصال بمكالمة الصوت أو الفيديو. حاول مرة أخرى بعد قليل.';

  @override
  String get rtcCallJoinRejected =>
      'تعذّر الانضمام إلى هذه المكالمة. اخرج من أي مكالمة مفتوحة لهذه الجلسة، انتظر لحظة، ثم حاول مجدداً.';

  @override
  String get rtcCallJoinInvalidToken =>
      'انتهت صلاحية رابط المكالمة أو أنه غير صالح. اضغط انضمام مرة أخرى للحصول على اتصال جديد.';

  @override
  String get webrtcSignalingUnavailable =>
      'مكالمات WebRTC داخل التطبيق غير متاحة بعد. اختر الصوت عبر Agora أو رابط اجتماع خارجي.';

  @override
  String get inAppCallShellTitle => 'مكالمة الجلسة';

  @override
  String get inAppCallShellBody =>
      'أنت متصل بغرفة هذه الجلسة. أنهِ المكالمة عند انتهاء الدرس.';

  @override
  String get inAppCallShellEndCall => 'مغادرة المكالمة';

  @override
  String get inAppCallShellMute => 'كتم الصوت';

  @override
  String get inAppCallShellUnmute => 'تشغيل الصوت';

  @override
  String get inAppCallShellConnecting => 'جارٍ الاتصال…';

  @override
  String get inAppCallShellConnected => 'متصل';

  @override
  String get inAppCallShellWaitingForParticipant => 'في انتظار الطرف الآخر';

  @override
  String get inAppCallShellMockBetaBody =>
      'معاينة تجريبية — لا يوجد صوت أو فيديو مباشر. احجز جلسة جديدة مع تفعيل Agora لتجربة مكالمة حقيقية.';

  @override
  String get inAppCallShellSpeaker => 'مكبر الصوت';

  @override
  String get inAppCallShellFlipCamera => 'تبديل الكاميرا';

  @override
  String get inAppCallShellTurnVideoOn => 'تشغيل الكاميرا';

  @override
  String get inAppCallShellTurnVideoOff => 'إيقاف الكاميرا';

  @override
  String get inAppCallShellMicrophoneMuted => 'تم كتم الميكروفون';

  @override
  String get inAppCallShellMicrophoneUnmuted => 'تم تشغيل الميكروفون';

  @override
  String get inAppCallShellCameraOff => 'تم إيقاف الكاميرا';

  @override
  String get inAppCallShellCameraOn => 'تم تشغيل الكاميرا';

  @override
  String get inAppCallShellSwitchCameraBlocked =>
      'لا يمكن تبديل الكاميرا أثناء إيقافها';

  @override
  String get inAppCallShellSpeakerOn => 'تم تشغيل السماعة';

  @override
  String get inAppCallShellSpeakerOff => 'تم إيقاف السماعة';

  @override
  String get inAppCallShellControlActionFailed =>
      'تعذر تنفيذ الإجراء، حاول مرة أخرى';

  @override
  String get externalMeetingJoinTitle => 'الانضمام خارج MeMuslim؟';

  @override
  String get externalMeetingJoinBody =>
      'ستغادر MeMuslim مؤقتًا للانضمام إلى جلستك عبر Google Meet أو Zoom أو المتصفح. يمكنك العودة هنا في أي وقت — تفاصيل جلستك تبقى مفتوحة.';

  @override
  String get externalMeetingJoinOpen => 'فتح';

  @override
  String get externalMeetingJoinCopy => 'نسخ الرابط';

  @override
  String get externalMeetingJoinLinkCopied => 'تم نسخ الرابط';

  @override
  String get externalMeetingJoinAgain => 'فتح الاجتماع مرة أخرى';

  @override
  String get externalMeetingLaunchFailed =>
      'تعذّر فتح رابط الاجتماع. حاول مرة أخرى أو انسخ الرابط.';

  @override
  String get externalMeetingLinkCopied =>
      'تم نسخ رابط الاجتماع. الصقه في المتصفح للانضمام.';

  @override
  String get groupBookingNotSupported =>
      'الجلسات الجماعية غير متاحة في النسخة التجريبية.';

  @override
  String get unsupportedSessionMode => 'نوع الجلسة غير مدعوم.';

  @override
  String get reviewSubmittedThanks => 'شكراً — تم إرسال تقييمك!';

  @override
  String get sessionReviewTitle => 'قيّم جلستك';

  @override
  String sessionReviewSubtitle(String teacherName) {
    return 'كيف كانت جلستك مع $teacherName؟';
  }

  @override
  String get sessionReviewSubtitleGeneric => 'كيف كانت جلستك؟';

  @override
  String get sessionReviewRatingLabel => 'تقييمك';

  @override
  String sessionReviewStarLabel(int star) {
    return '$star نجوم';
  }

  @override
  String get sessionReviewCommentLabel => 'تعليق (اختياري)';

  @override
  String get sessionReviewCommentHint => 'شارك ما أعجبك أو ما يمكن تحسينه';

  @override
  String get sessionReviewSubmit => 'إرسال التقييم';

  @override
  String get sessionReviewSkip => 'ليس الآن';

  @override
  String get rateSessionAction => 'قيّم الجلسة';

  @override
  String get reportTutorAction => 'الإبلاغ عن المحفظ';

  @override
  String upcomingSessionsSection(int count) {
    return 'الحصص القادمة ($count)';
  }

  @override
  String get noUpcomingSessions => 'لا توجد جلسات قادمة';

  @override
  String pastSessionsSection(int count) {
    return 'السابقة ($count)';
  }

  @override
  String get loadMorePastSessions => 'تحميل المزيد';

  @override
  String get noPastSessions => 'لا توجد جلسات سابقة';

  @override
  String get cancelSessionDialogTitle => 'إلغاء الجلسة؟';

  @override
  String get cancelSessionDialogMessage => 'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get keepSession => 'بقاء';

  @override
  String get cancelSessionAction => 'إلغاء الجلسة';

  @override
  String get cancelReasonLabel => 'سبب الإلغاء';

  @override
  String get cancelReasonHint => 'أخبرنا لماذا تحتاج إلى الإلغاء (مطلوب)';

  @override
  String get cancelReasonRequired => 'يرجى إدخال 3 أحرف على الأقل.';

  @override
  String get cancelPolicyBlockedNotice =>
      'لا يُسمح بالإلغاء قرب موعد بدء الجلسة.';

  @override
  String get cancellationFreeNoRefund => 'هذه جلسة مجانية. لا يوجد استرداد.';

  @override
  String get cancelPolicyFullRefund => 'ستحصل على استرداد كامل إذا ألغيت الآن.';

  @override
  String get cancelPolicyPartialRefund =>
      'قد ينطبق استرداد جزئي وفق سياسة الإلغاء.';

  @override
  String get cancelPolicyNoRefund => 'لا ينطبق استرداد للإلغاء في هذا الوقت.';

  @override
  String get tutorCancelSessionDialogTitle => 'إلغاء الحصة؟';

  @override
  String get tutorCancelSessionDialogMessage =>
      'سيتم إبلاغ الطالب بإلغاء الحصة، ولن يتمكن من الانضمام إليها.';

  @override
  String get tutorCancelSessionAction => 'إلغاء الحصة';

  @override
  String get tutorCancelSessionGoBack => 'تراجع';

  @override
  String get tutorCancelSessionSuccess => 'تم إلغاء الحصة';

  @override
  String get tutorCancelSessionError => 'تعذّر إلغاء الحصة، حاول مرة أخرى';

  @override
  String get sessionCancelledByTutorTitle => 'اعتذر المحفظ عن إلغاء الحصة';

  @override
  String get sessionCancelledByTutorSubtitle => 'يمكنك اختيار موعد آخر';

  @override
  String get rescheduleSessionTitle => 'إعادة جدولة الجلسة';

  @override
  String get rescheduleReasonLabel => 'سبب إعادة الجدولة';

  @override
  String get rescheduleReasonHint => 'اشرح باختصار لماذا تحتاج وقتاً جديداً';

  @override
  String get rescheduleSubmitAction => 'طلب إعادة الجدولة';

  @override
  String get rescheduleRequestSubmitted =>
      'تم إرسال طلب إعادة الجدولة. بانتظار التأكيد.';

  @override
  String get rescheduleAwaitingCounterparty =>
      'بانتظار تأكيد الطرف الآخر للوقت الجديد.';

  @override
  String get reschedulePendingTitle => 'طلب إعادة جدولة';

  @override
  String reschedulePendingProposedTime(String dateTime) {
    return 'الوقت المقترح: $dateTime';
  }

  @override
  String reschedulePendingReason(String reason) {
    return 'السبب: $reason';
  }

  @override
  String get rescheduleAcceptAction => 'قبول الوقت الجديد';

  @override
  String get rescheduleRejectAction => 'الإبقاء على الوقت الحالي';

  @override
  String get rescheduleAcceptedToast =>
      'تم قبول إعادة الجدولة وتحديث وقت الجلسة.';

  @override
  String get rescheduleRejectedToast =>
      'تم رفض إعادة الجدولة والإبقاء على الوقت الأصلي.';

  @override
  String get rescheduleAction => 'إعادة الجدولة';

  @override
  String get sessionDetailTitle => 'تفاصيل الجلسة';

  @override
  String get sessionTimelineTitle => 'سجل النشاط';

  @override
  String get sessionTimelineEmpty => 'لا يوجد نشاط مسجل بعد.';

  @override
  String get sessionTimelineLoadFailed =>
      'تعذّر تحميل سجل النشاط. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get sessionPendingRescheduleLoadFailed =>
      'تعذّر تحميل طلب إعادة الجدولة المعلّق. حاول مرة أخرى بعد قليل.';

  @override
  String sessionLockedAtBookingNote(String callType, String callProvider) {
    return 'نوع المكالمة ($callType) والمزوّد ($callProvider) حُدّدا عند الحجز. لتغييرهما، ألغِ الجلسة وأعد الحجز أو تواصل مع الدعم.';
  }

  @override
  String get callProviderExternal => 'رابط خارجي';

  @override
  String get callProviderMock => 'داخل التطبيق (معاينة)';

  @override
  String get callProviderAgora => 'داخل التطبيق (Agora)';

  @override
  String get callProviderLivekit => 'داخل التطبيق (LiveKit)';

  @override
  String sessionStatusLabel(String status) {
    return 'الحالة: $status';
  }

  @override
  String sessionStartsAtLabel(String when) {
    return 'تبدأ: $when';
  }

  @override
  String get viewSessionDetails => 'عرض التفاصيل';

  @override
  String get sessionCardOverflowMenu => 'إجراءات الجلسة';

  @override
  String get noSessionsYet => 'لا توجد جلسات بعد';

  @override
  String get bookFirstSessionHint =>
      'احجز جلستك الأولى مع أحد معلمينا المعتمدين';

  @override
  String get teacherProfileTitle => 'ملف المعلم';

  @override
  String teacherRatingReviews(String rating, int count) {
    return '$rating · $count تقييم';
  }

  @override
  String get availableSlots => 'المواعيد المتاحة';

  @override
  String get reviewsSection => 'التقييمات';

  @override
  String get noReviewsYet => 'لا توجد تقييمات بعد';

  @override
  String get aboutTeacherSection => 'نبذة عن المعلم';

  @override
  String get bookSessionAction => 'احجز جلسة';

  @override
  String get noAvailabilityBookAction => 'لا توجد مواعيد متاحة';

  @override
  String get sessionStatusScheduled => 'مجدول';

  @override
  String get sessionStatusInProgress => 'جارٍ الآن';

  @override
  String get sessionStatusCompleted => 'مكتمل';

  @override
  String get sessionStatusCancelled => 'ملغى';

  @override
  String get sessionStatusNoShow => 'غائب';

  @override
  String get cancel => 'إلغاء';

  @override
  String get joinSession => 'انضمام';

  @override
  String get sessionJoinStateNotStarted =>
      'يفتح الانضمام قبل ١٥ دقيقة من بدء الجلسة.';

  @override
  String get sessionJoinStateJoinAvailable => 'يمكنك الانضمام الآن.';

  @override
  String get sessionJoinStateJoining => 'جارٍ الاتصال بالجلسة…';

  @override
  String get sessionJoinStateJoined => 'انضممت إلى هذه الجلسة.';

  @override
  String get sessionJoinStateFailed =>
      'تعذّر الانضمام. أعد المحاولة أو تواصل مع الدعم.';

  @override
  String get sessionJoinStateEnded => 'انتهت هذه الجلسة.';

  @override
  String get sessionJoinStateCancelled => 'أُلغيت هذه الجلسة.';

  @override
  String get sessionCancelledSuccess => 'تم إلغاء الجلسة.';

  @override
  String get noSlotsAvailable => 'لا توجد مواعيد متاحة';

  @override
  String get noSlotsAvailableThisDay => 'لا توجد مواعيد متاحة في هذا اليوم';

  @override
  String get slotPickerLocalTimezoneNote => 'الأوقات معروضة بتوقيتك المحلي';

  @override
  String teacherSessionsCompleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count جلسة مكتملة',
      one: 'جلسة واحدة مكتملة',
    );
    return '$_temp0';
  }

  @override
  String get teacherDashboardTitle => 'لوحة المعلم';

  @override
  String get noSessionsOrSlotsYet => 'لا توجد جلسات أو مواعيد بعد';

  @override
  String get addAvailableSlot => 'أضف موعداً متاحاً';

  @override
  String openSlotsSection(int count) {
    return 'المواعيد المفتوحة ($count)';
  }

  @override
  String get addSlot => 'أضف موعداً';

  @override
  String get noOpenSlots => 'لا توجد مواعيد مفتوحة';

  @override
  String get slotBooked => 'محجوز';

  @override
  String get slotAvailable => 'متاح';

  @override
  String get editSlot => 'تعديل الموعد';

  @override
  String get deleteSlot => 'حجب هذا الوقت';

  @override
  String get deleteSlotConfirmTitle => 'حجب هذا الوقت؟';

  @override
  String get deleteSlotConfirmMessage =>
      'لن يتمكن الطلاب من حجز هذا الوقت. اضغط تراجع في الإشعار لاستعادته.';

  @override
  String get deleteSlotConfirm => 'حجب الوقت';

  @override
  String get deleteSlotSuccess => 'تم حجب الوقت';

  @override
  String get deleteSlotUndo => 'تراجع';

  @override
  String deleteSlotRemovedSnackBar(String time) {
    return 'تم حجب $time';
  }

  @override
  String deleteSlotRemovedSnackBarWithPending(String time, int count) {
    return 'تم حجب $time ($count قيد الانتظار)';
  }

  @override
  String deleteSlotRefreshDiscarded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم إلغاء $count عمليات حجب قيد الانتظار — تمت استعادة المواعيد',
      one: 'تم إلغاء حجب واحد قيد الانتظار — تمت استعادة المواعيد',
    );
    return '$_temp0';
  }

  @override
  String get addNewSlot => 'إضافة موعد جديد';

  @override
  String get slotDate => 'تاريخ الموعد';

  @override
  String get slotTime => 'وقت الموعد';

  @override
  String get addSlotButton => 'إضافة الموعد';

  @override
  String get availabilityTitle => 'التوفر الأسبوعي';

  @override
  String get availabilityAppBarTitle => 'المواعيد';

  @override
  String get availabilityRecurringBanner =>
      'هذا توفرك الأسبوعي المتكرر. يُستخدم لإنشاء المواعيد القابلة للحجز في الأيام القادمة.';

  @override
  String get bookableTimesSectionTitle => 'المواعيد المتاحة خلال 14 يوم';

  @override
  String get bookableTimesSectionSubtext =>
      'يتم إنشاء هذه المواعيد من توفرك الأسبوعي مع استبعاد الاستثناءات والحجوزات.';

  @override
  String get bookableTimesThisWeekSectionTitle => 'هذا الأسبوع';

  @override
  String get bookableTimesNextWeekSectionTitle => 'الأسبوع القادم';

  @override
  String get bookableTimesWeekScopedTitle => 'المواعيد القابلة للحجز';

  @override
  String bookableTimesSelectedDayCaption(String dayLabel) {
    return 'عرض مواعيد $dayLabel';
  }

  @override
  String get bookableTimesEmptyThisWeek =>
      'لا توجد مواعيد قابلة للحجز هذا الأسبوع.';

  @override
  String get bookableTimesEmptyNextWeek =>
      'لا توجد مواعيد قابلة للحجز الأسبوع القادم.';

  @override
  String get bookableTimesEmptyThisWeekTitle =>
      'لا توجد مواعيد قابلة للحجز هذا الأسبوع';

  @override
  String get bookableTimesEmptyThisWeekSubtitle =>
      'الأيام المفتوحة في جدولك الأسبوعي تتحول إلى مواعيد هنا. عدّل ساعاتك أو راجع الاستثناءات إن كنت تتوقع مواعيد.';

  @override
  String get bookableTimesEmptyNextWeekTitle =>
      'لا توجد مواعيد قابلة للحجز الأسبوع القادم';

  @override
  String get bookableTimesEmptyNextWeekSubtitle =>
      'يُبنى الأسبوع القادم من توفرك الأسبوعي المتكرر. راجع جدولك لإضافة أيام أو تعديلها.';

  @override
  String get bookableTimesEmptyHorizonTitle =>
      'لا توجد مواعيد قابلة للحجز خلال 14 يومًا';

  @override
  String get bookableTimesEmptyHorizonSubtitle =>
      'حدد توفرك الأسبوعي المتكرر وستظهر المواعيد تلقائيًا للأيام المفتوحة.';

  @override
  String get upcomingSessionsEmptyTitle => 'لا توجد حصص قادمة';

  @override
  String get upcomingSessionsEmptySubtitle =>
      'ستظهر الحجوزات المؤكدة هنا عندما يحجز الطلاب موعدًا معك.';

  @override
  String get fridayReviewBannerMessage =>
      'راجع توفرك للأسبوع القادم. يحجز الطلاب من جدولك الأسبوعي.';

  @override
  String get fridayReviewBannerAction => 'مراجعة';

  @override
  String get fridayReviewBannerDismiss => 'تجاهل';

  @override
  String get editWeeklyTemplate => 'تعديل الجدول الأسبوعي';

  @override
  String get availabilityTabHours => 'الساعات';

  @override
  String get availabilityTabOverrides => 'الاستثناءات';

  @override
  String get availabilityUseSameHours => 'استخدام نفس الساعات لكل الأيام';

  @override
  String get availabilityTimezone => 'المنطقة الزمنية';

  @override
  String get availabilitySessionLength => 'مدة الحصة';

  @override
  String availabilityDurationMinutes(int count) {
    return '$count دقيقة';
  }

  @override
  String get availabilityHoursRow => 'الساعات';

  @override
  String get availabilityDayClosed => 'مغلق';

  @override
  String get availabilityAddRange => 'إضافة فترة';

  @override
  String get availabilityEditRange => 'تعديل الفترة';

  @override
  String get availabilityRemoveRange => 'حذف';

  @override
  String get availabilitySave => 'حفظ';

  @override
  String get availabilitySavedToast => 'تم حفظ الجدول';

  @override
  String get availabilityOverrideRemovedToast => 'تم حذف الاستثناء';

  @override
  String get availabilityOverrideAddedToast => 'تمت إضافة الاستثناء';

  @override
  String get availabilityDeleteVacationTitle => 'حذف الإجازة؟';

  @override
  String get availabilityDeleteVacationMessage =>
      'ستصبح هذه التواريخ متاحة للطلاب للحجز مرة أخرى.';

  @override
  String get availabilityDeleteVacationConfirm => 'حذف الإجازة';

  @override
  String get availabilityVacationOverlapError =>
      'تتداخل هذه التواريخ مع إجازة موجودة. عدّل الفترة أو احذف الإجازة الحالية أولاً.';

  @override
  String get availabilityUnsavedChanges => 'تغييرات غير محفوظة';

  @override
  String get availabilityLoadError => 'تعذّر تحميل جدولك';

  @override
  String get availabilityStartTime => 'وقت البدء';

  @override
  String get availabilityEndTime => 'وقت الانتهاء';

  @override
  String get availabilityUseTheseTimes => 'استخدام هذه الأوقات';

  @override
  String get availabilityRangeInvalid =>
      'يجب أن يكون وقت الانتهاء بعد وقت البدء';

  @override
  String get availabilityRangeOverlap => 'تتداخل هذه الفترة مع فترة أخرى';

  @override
  String get availabilityNoOpenDaysError =>
      'اختر يوماً واحداً على الأقل مع ساعات عمل';

  @override
  String get availabilityOverridesEmpty => 'لا توجد استثناءات بعد';

  @override
  String get availabilityOverridesEmptyHint =>
      'احجب يوماً كإجازة أو أضف ساعات خاصة لتاريخ محدد.';

  @override
  String get availabilityAddOverride => 'إضافة استثناء';

  @override
  String get availabilityOverrideUnavailable => 'غير متاح (إجازة)';

  @override
  String get availabilityOverrideCustom => 'ساعات مخصّصة';

  @override
  String get availabilityOverrideDate => 'التاريخ';

  @override
  String get availabilityOverrideStartDate => 'من';

  @override
  String get availabilityOverrideEndDate => 'إلى';

  @override
  String get availabilityOverrideEndDateInvalid =>
      'يجب أن يكون تاريخ الانتهاء في نفس يوم البدء أو بعده';

  @override
  String get availabilitySetupHeadline =>
      'حدد أوقاتك مرة واحدة وسيتمكن الطلاب من الحجز تلقائيًا';

  @override
  String get availabilitySetupCta => 'إعداد الجدول الأسبوعي';

  @override
  String get availabilitySetupBenefitRecurring => 'لا تكرار يدوي';

  @override
  String get availabilitySetupBenefitTimezone => 'مراعاة المناطق الزمنية';

  @override
  String get availabilitySetupBenefitSelfBooking => 'يحجز الطلاب بأنفسهم';

  @override
  String get availabilityTimezonePickerTitle => 'اختر المنطقة الزمنية';

  @override
  String get availabilityDiscardChanges => 'تجاهل التغييرات؟';

  @override
  String get availabilityDiscardConfirm => 'تجاهل';

  @override
  String get availabilityKeepEditing => 'متابعة التعديل';

  @override
  String get weekdaySaturday => 'السبت';

  @override
  String get weekdaySunday => 'الأحد';

  @override
  String get weekdayMonday => 'الإثنين';

  @override
  String get weekdayTuesday => 'الثلاثاء';

  @override
  String get weekdayWednesday => 'الأربعاء';

  @override
  String get weekdayThursday => 'الخميس';

  @override
  String get weekdayFriday => 'الجمعة';

  @override
  String get teacherApplicationTitle => 'طلب تسجيل كمحفظ';

  @override
  String get submittingApplication => 'جارٍ إرسال الطلب…';

  @override
  String get becomeTeacherOnTilawa => 'أصبح محفظًا على MeMuslim';

  @override
  String get becomeTeacherApplicationIntro =>
      'انضم إلى نخبة المعلمين المعتمدين وساعد الطلاب في رحلتهم مع القرآن الكريم.';

  @override
  String get startApplication => 'ابدأ طلب التسجيل';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get phoneNumberRequiredHint =>
      'مطلوب للتحقق من هويتك. يظهر للإدارة فقط.';

  @override
  String get preferredContactMethod => 'طريقة التواصل المفضلة';

  @override
  String get teachingLanguages => 'لغات التدريس';

  @override
  String get teachingLanguagesSelect => 'لغات التدريس * (اختر واحدة أو أكثر)';

  @override
  String get specializations => 'التخصصات';

  @override
  String get specializationsSelect => 'التخصصات * (اختر واحداً أو أكثر)';

  @override
  String get bio => 'النبذة التعريفية';

  @override
  String get bioSectionTitle => 'نبذة تعريفية *';

  @override
  String get bioHint => 'أخبر الطلاب عن خبرتك ومؤهلاتك وأسلوبك في التدريس…';

  @override
  String get submitApplicationForReview => 'إرسال الطلب للمراجعة';

  @override
  String get countryCode => 'رمز الدولة';

  @override
  String get contactWhatsapp => 'واتساب';

  @override
  String get contactPhone => 'هاتف';

  @override
  String get contactEmail => 'بريد إلكتروني';

  @override
  String get teachingLanguage_ar => 'العربية';

  @override
  String get teachingLanguage_en => 'الإنجليزية';

  @override
  String get teachingLanguage_ur => 'الأردية';

  @override
  String get teachingLanguage_fr => 'الفرنسية';

  @override
  String get teachingLanguage_tr => 'التركية';

  @override
  String get teachingLanguage_ms => 'الملايوية';

  @override
  String get specialization_tajweed => 'تجويد';

  @override
  String get specialization_recitation => 'تلاوة';

  @override
  String get specialization_hifz => 'حفظ';

  @override
  String get specialization_review => 'مراجعة';

  @override
  String get specialization_children => 'تعليم الأطفال';

  @override
  String get specialization_qaida => 'القاعدة النورانية';

  @override
  String get specialization_tafsir => 'تفسير';

  @override
  String get specialization_arabic => 'اللغة العربية';

  @override
  String get applicationStatusTitle => 'حالة طلب التسجيل';

  @override
  String get unknownStatus => 'حالة غير معروفة';

  @override
  String get applicationStatusPendingTitle => 'طلبك قيد المراجعة';

  @override
  String get applicationStatusPendingSubtitle =>
      'يقوم فريق MeMuslim بمراجعة طلبك. سنتواصل معك قريبًا.';

  @override
  String get applicationStatusApprovedTitle => 'تهانينا! تمت الموافقة';

  @override
  String get applicationStatusApprovedSubtitle =>
      'أصبحت محفظًا معتمدًا على MeMuslim.';

  @override
  String get applicationStatusApprovedContinue => 'متابعة';

  @override
  String get applicationStatusRejectedTitle => 'لم تتم الموافقة على الطلب';

  @override
  String get applicationStatusRejectedSubtitle =>
      'يمكنك إعادة التقديم بعد مراجعة ملاحظات الفريق.';

  @override
  String get applicationStatusSuspendedTitle => 'الحساب موقوف مؤقتًا';

  @override
  String get applicationStatusSuspendedSubtitle =>
      'تواصل مع الدعم للاستفسار عن سبب التوقف.';

  @override
  String get applicationStatusRevokedTitle => 'تم إلغاء الحساب';

  @override
  String get applicationStatusRevokedSubtitle =>
      'لا يمكنك التقديم مجددًا. تواصل مع الدعم للمزيد.';

  @override
  String get submittedAtLabel => 'تاريخ الإرسال';

  @override
  String get reviewedAtLabel => 'تاريخ المراجعة';

  @override
  String get reasonLabel => 'السبب';

  @override
  String labelWithColon(String label) {
    return '$label:';
  }

  @override
  String get debugModeTitle => 'وضع التطوير';

  @override
  String get debugApprovalDescription =>
      'هذا الزر للاختبار الداخلي فقط ولا يظهر في نسخة الإنتاج. يحاكي موافقة المشرف دون الحاجة إلى واجهة إدارة.';

  @override
  String get simulateAdminApproval => 'محاكاة موافقة المشرف';

  @override
  String get priceFree => 'مجاني';

  @override
  String pricePerSession(String amount) {
    return '$amount / جلسة';
  }

  @override
  String get teachingOnMemuslimTitle => 'التدريس على MeMuslim';

  @override
  String get teachingOnMemuslimApply => 'التقديم كمحفظ';

  @override
  String get teachingOnMemuslimContinueDraft => 'استكمال طلب التسجيل';

  @override
  String get teachingOnMemuslimViewStatus => 'عرض حالة الطلب';

  @override
  String get teachingOnMemuslimTeacherDashboard => 'لوحة تحكم المحفظ';

  @override
  String get teachingOnMemuslimOpenDashboard => 'فتح لوحة المعلم';

  @override
  String get teachingOnMemuslimManageScheduleSubtitle =>
      'يمكنك إدارة مواعيدك وجلساتك من هنا';

  @override
  String get teachingOnMemuslimReapplySubtitle =>
      'اعرض التفاصيل أو أعد التقديم عند السماح.';

  @override
  String get verifiedTeacherBadge => 'محفظ معتمد';

  @override
  String get teacherCapabilityStatusDraft => 'مسودة';

  @override
  String get teacherCapabilityStatusPending => 'قيد المراجعة';

  @override
  String get teacherCapabilityStatusRejected => 'مرفوض';

  @override
  String get teacherCapabilityStatusSuspended => 'موقوف';

  @override
  String get teacherCapabilityStatusRevoked => 'تم إلغاء الاعتماد';

  @override
  String get teachingOnMemuslimNotAppliedSubtitle =>
      'قدّم طلبك للانضمام كمحفظ معتمد بعد مراجعة الفريق.';

  @override
  String get teachingOnMemuslimPendingSubtitle =>
      'طلبك قيد المراجعة. سنتواصل معك قريبًا.';

  @override
  String get teachingOnMemuslimApprovedSubtitle =>
      'تمت الموافقة على طلبك. يمكنك إدارة جلساتك من لوحة المعلم.';

  @override
  String get teachingOnMemuslimRejectedSubtitle =>
      'لم تتم الموافقة على الطلب. يمكنك عرض التفاصيل وإعادة التقديم عند السماح.';

  @override
  String get teachingOnMemuslimSuspendedSubtitle =>
      'حسابك كمعلم موقوف مؤقتًا. تواصل مع الدعم للاستفسار.';

  @override
  String get teachingOnMemuslimRevokedSubtitle =>
      'تم إلغاء حسابك كمعلم. تواصل مع الدعم للمزيد.';

  @override
  String get sessionsEmptyTitle => 'لا يوجد معلمون في منطقتك بعد';

  @override
  String get sessionsEmptySubtitle =>
      'نضيف محفظين معتمدين تدريجيًا. سجّل اهتمامك لنبلغك عند توفر معلم.';

  @override
  String get sessionsEmptyNotifyMe => 'أبلغني عند التوفر';

  @override
  String get sessionsEmptyChangeCity => 'تغيير المدينة';

  @override
  String get sessionsEmptyInterestedTeaching => 'هل ترغب في تدريس القرآن؟';

  @override
  String get sessionsEmptyJoinAsTeacher => 'انضم كمحفظ';

  @override
  String get notifyInterestSubmitted => 'سنبلغك عند توفر معلمين في منطقتك.';

  @override
  String get teacherApplicationDisabled => 'التقديم كمحفظ غير متاح حاليًا.';

  @override
  String get bookingDisabledNoSupply =>
      'الحجز غير متاح حتى يتوفر معلمون معتمدون في منطقتك.';

  @override
  String get completeTeacherProfileTitle => 'إكمال ملف المحفظ';

  @override
  String get completeTeacherProfileSubtitle =>
      'أضف البيانات العامة التي يراها الطلاب قبل فتح لوحة التحكم.';

  @override
  String get completeTeacherProfileFirstMessage =>
      'أكمل ملف المحفظ قبل فتح لوحة التحكم.';

  @override
  String get teacherDashboard => 'لوحة تحكم المحفظ';

  @override
  String get openTeacherDashboard => 'فتح لوحة تحكم المحفظ';

  @override
  String get completeTeacherProfile => 'أكمل ملف المعلم';

  @override
  String get teacherPublicNameLabel => 'الاسم الحقيقي للمعلم';

  @override
  String get teacherPublicNameHelper =>
      'الاسم الحقيقي / اسم المعلم الظاهر للطلاب في السوق. قد يختلف عن اسم حسابك.';

  @override
  String get teacherExternalMeetingUrlLabel => 'رابط الاجتماع الخارجي';

  @override
  String get teacherExternalMeetingUrlHint =>
      'https://meet.google.com/your-room';

  @override
  String get teacherExternalMeetingUrlHelper =>
      'الطلاب الذين يحجزون جلسات خارجية ينضمون عبر هذا الرابط الآمن (Google Meet أو Zoom أو Teams).';

  @override
  String get teacherExternalMeetingUrlSaved => 'تم حفظ رابط الاجتماع';

  @override
  String get teacherExternalMeetingUrlSave => 'حفظ رابط الاجتماع';

  @override
  String get teacherExternalMeetingUrlInvalid =>
      'أدخل رابط اجتماع صالحًا يبدأ بـ https (Google Meet أو Zoom أو Teams).';

  @override
  String get teacherOffersExternalSessions => 'جلسات خارجية متاحة';

  @override
  String get sessionMeetingLinkLabel => 'رابط الاجتماع';

  @override
  String get teacherPublicNameRequired => 'الاسم الحقيقي للمعلم مطلوب.';

  @override
  String get teacherPublicNameInvalid =>
      'أدخل اسمًا حقيقيًا صالحًا (3 أحرف على الأقل، أو كلمتين).';

  @override
  String get teacherPublicNamePlaceholderNotAllowed =>
      'اختر اسمك الحقيقي الكامل — الأسماء العامة مثل «محفظ قرآن» غير مسموحة.';

  @override
  String get teacherProfileHiddenUntilComplete =>
      'يبقى ملفك مخفيًا عن الطلاب حتى تكتمل جميع الحقول العامة المطلوبة.';

  @override
  String get publicTeacherName => 'الاسم الحقيقي للمعلم';

  @override
  String get visibleToStudents => 'اسمك الكامل الظاهر للطلاب';

  @override
  String get realNameRequiredForTeachers =>
      'يجب على المعلمين استخدام اسم علني حقيقي يتعرّف عليه الطلاب.';

  @override
  String get teachingLanguagesRequired => 'اختر لغة تدريس واحدة على الأقل.';

  @override
  String get specializationsRequired => 'اختر تخصصًا واحدًا على الأقل.';

  @override
  String get bioRequired => 'النبذة التعريفية مطلوبة.';

  @override
  String get teacherProfileUnavailableTitle => 'ملف المعلم غير متاح';

  @override
  String get teacherProfileUnavailableSubtitle =>
      'لم يكمل هذا المعلم ملفه العام بعد.';

  @override
  String get verifiedTeacher => 'محفظ معتمد';

  @override
  String get quranTeacherFallbackName => 'محفظ قرآن';

  @override
  String get teacherProfileIncomplete =>
      'ملف المحفظ العام ناقص بعض الحقول المطلوبة.';

  @override
  String get teacherProfileIncompleteAction => 'إكمال الملف';

  @override
  String get manageYourAvailabilityAndSessions =>
      'يمكنك إدارة مواعيدك وجلساتك من هنا';

  @override
  String get noAvailabilityYet => 'لم تُنشر أي مواعيد بعد.';

  @override
  String get noAvailabilityHelper =>
      'يمكنك العودة لاحقًا عند إضافة مواعيد جديدة.';

  @override
  String get reportConcernAction => 'الإبلاغ عن مخاوف';

  @override
  String get reportConcernTitle => 'الإبلاغ عن مخاوف تتعلق بالسلامة';

  @override
  String get reportConcernSubtitle =>
      'أخبرنا بما حدث. سيقوم فريقنا بمراجعة البلاغات بسرعة.';

  @override
  String get reportConcernCategory => 'الفئة';

  @override
  String get reportConcernDescriptionLabel => 'الوصف';

  @override
  String get reportConcernDescriptionHint => 'صف ما حدث (20 حرفاً على الأقل)';

  @override
  String get reportConcernDescriptionTooShort =>
      'يُرجى كتابة 20 حرفاً على الأقل.';

  @override
  String get reportConcernCancel => 'إلغاء';

  @override
  String get reportConcernSubmit => 'إرسال البلاغ';

  @override
  String get reportConcernSubmitted => 'تم إرسال بلاغك. سيراجعه فريقنا.';

  @override
  String get openDisputeAction => 'فتح نزاع';

  @override
  String get openDisputeTitle => 'فتح نزاع';

  @override
  String get openDisputeSubtitle => 'أخبرنا بما حدث. سيراجع فريقنا حالتك.';

  @override
  String get openDisputeReasonLabel => 'السبب';

  @override
  String get openDisputeReasonHint => 'صف المشكلة (3 أحرف على الأقل)';

  @override
  String get openDisputeReasonTooShort => 'يُرجى كتابة 3 أحرف على الأقل.';

  @override
  String get openDisputeCancel => 'إلغاء';

  @override
  String get openDisputeSubmit => 'إرسال النزاع';

  @override
  String get openDisputeSubmitted => 'تم إرسال نزاعك. سيراجعه فريقنا.';

  @override
  String get reportCategorySafetyConcern => 'مخاوف تتعلق بالسلامة';

  @override
  String get reportCategoryAbuseOrHarassment => 'إساءة أو تحرش';

  @override
  String get reportCategoryInappropriateContent => 'محتوى غير لائق';

  @override
  String get reportCategoryChildSafety => 'سلامة الأطفال';

  @override
  String get reportCategoryFraudOrScam => 'احتيال';

  @override
  String get reportCategoryOther => 'أخرى';

  @override
  String get walletTitle => 'محفظتي';

  @override
  String get walletAppBarTitle => 'المحفظة';

  @override
  String get walletAvailableBalanceLabel => 'الرصيد المتاح';

  @override
  String walletHeldBalanceLabel(String amount) {
    return 'محجوز: $amount';
  }

  @override
  String get walletTransactionsTitle => 'سجل المعاملات';

  @override
  String get walletEmptyState => 'تظهر الأرصدة عند معالجة الاستردادات.';

  @override
  String get walletFrozenMessage =>
      'المحفظة غير متاحة مؤقتًا — تواصل مع الدعم.';

  @override
  String walletTransactionTypeLabel(String type) {
    return '$type';
  }

  @override
  String get walletTransactionTypeRefund => 'استرداد';

  @override
  String get walletTransactionTypeCompensation => 'تعويض';

  @override
  String get walletTransactionTypeAdmin => 'رصيد إداري';

  @override
  String get walletTransactionTypePromo => 'رصيد ترويجي';

  @override
  String get walletTransactionTypeBooking => 'دفع جلسة';

  @override
  String get walletTransactionTypeHold => 'حجز';

  @override
  String get walletTransactionTypeHoldRelease => 'إلغاء حجز';

  @override
  String get walletTransactionTypeReversal => 'عكس معاملة';

  @override
  String get walletTransactionTypeExpiry => 'رصيد منتهٍ';

  @override
  String get walletEntryAction => 'المحفظة';

  @override
  String get paymentCheckoutTitle => 'تأكيد الدفع';

  @override
  String get paymentCheckoutFreeTitle => 'تأكيد الحجز';

  @override
  String get paymentCheckoutFreeAmount => 'هذه الجلسة مجانية — لا يلزم دفع.';

  @override
  String paymentCheckoutAmount(String amount) {
    return 'الإجمالي: $amount';
  }

  @override
  String get paymentCheckoutAmountPending => 'سعر الجلسة (تجريبي)';

  @override
  String get paymentCheckoutSandboxNotice =>
      'وضع تجريبي — لا يتم خصم مبلغ حقيقي. تفعيل الحجز المدفوع عبر علم الإطلاق التجريبي فقط.';

  @override
  String get paymentCheckoutRefundToWalletNotice =>
      'عند الإلغاء أو الموافقة على استرداد، يُضاف المبلغ إلى محفظة أنا مسلم كرصيد. لا يُعاد الرصيد تلقائيًا إلى بطاقتك.';

  @override
  String get paymentCheckoutConfirm => 'تأكيد الدفع (تجريبي)';

  @override
  String get paymentCheckoutConfirmFree => 'تأكيد الحجز';

  @override
  String get bookingPriceSummaryTitle => 'سعر الجلسة';

  @override
  String get bookingPricePerSessionHint =>
      'يُخصم مرة واحدة عند التأكيد (تجريبي فقط).';

  @override
  String get walletSandboxNotice =>
      'محفظة تجريبية — أرصدة من الاستردادات والمدفوعات التجريبية فقط. ليست أموالًا حقيقية.';

  @override
  String get restrictionReasonFalseIdentity => 'بيانات هوية مزيفة';

  @override
  String get restrictionReasonPolicyViolation => 'مخالفة السياسات';

  @override
  String get restrictionReasonSafetyConcern => 'مخاوف تتعلق بالسلامة';

  @override
  String get restrictionReasonAbuseReport => 'بلاغ إساءة';

  @override
  String get restrictionReasonRepeatedNoShow => 'غياب متكرر';

  @override
  String get restrictionReasonAdminDecision => 'قرار إداري';

  @override
  String get sessionLifecycleDraft => 'مسودة';

  @override
  String get sessionLifecyclePendingPayment => 'بانتظار الدفع';

  @override
  String get sessionLifecycleScheduled => 'مجدولة';

  @override
  String get sessionLifecycleConfirmed => 'مؤكدة';

  @override
  String get sessionLifecycleInProgress => 'جارية';

  @override
  String get sessionLifecycleRescheduled => 'أُعيد جدولتها';

  @override
  String get sessionLifecycleCancelledByStudent => 'ألغاها الطالب';

  @override
  String get sessionLifecycleCancelledByTeacher => 'ألغاها المعلم';

  @override
  String get sessionLifecycleCancelledByAdmin => 'ألغاها المشرف';

  @override
  String get sessionStatusCancelledByTutorDetail =>
      'تم إلغاء الجلسة بواسطة المحفظ';

  @override
  String get sessionStatusCancelledByTutorSelf => 'ألغيت هذه الجلسة';

  @override
  String get sessionStatusCancelledByStudentDetail =>
      'تم إلغاء الجلسة بواسطة الطالب';

  @override
  String get sessionStatusCancelledByStudentSelf => 'ألغيت هذه الجلسة';

  @override
  String get sessionStatusCancelledBySupportDetail =>
      'تم إلغاء الجلسة بواسطة الإدارة';

  @override
  String get sessionStatusCancelledDescription => 'أُلغيت هذه الجلسة.';

  @override
  String get sessionTimelineBookingConfirmed => 'تم تأكيد الحجز';

  @override
  String get sessionTimelineCancelledByTutor => 'تم إلغاء الجلسة بواسطة المحفظ';

  @override
  String get sessionTimelineCancelledByStudent =>
      'تم إلغاء الجلسة بواسطة الطالب';

  @override
  String get sessionTimelineCancelledBySupport =>
      'تم إلغاء الجلسة بواسطة الإدارة';

  @override
  String get sessionCancelledDisputeHelper =>
      'يمكنك فتح نزاع إذا احتجت لفريقنا مراجعة هذا الإلغاء.';

  @override
  String get sessionLifecycleTeacherNoShow => 'غياب المعلم';

  @override
  String get sessionLifecycleStudentNoShow => 'غياب الطالب';

  @override
  String get sessionLifecycleBothNoShow => 'غياب الطرفين';

  @override
  String get sessionLifecycleIncomplete => 'غير مكتملة';

  @override
  String get sessionLifecycleCompleted => 'مكتملة';

  @override
  String get sessionLifecycleDisputed => 'متنازع عليها';

  @override
  String get sessionLifecycleCompensated => 'مُعوَّضة';

  @override
  String get sessionLifecycleRefunded => 'مُستردة';

  @override
  String get sessionLifecycleExpired => 'منتهية';

  @override
  String get sessionActionCreateDraft => 'إنشاء مسودة';

  @override
  String get sessionActionInitiatePayment => 'بدء الدفع';

  @override
  String get sessionActionConfirmBooking => 'تأكيد الحجز';

  @override
  String get sessionActionConfirmFreeBooking => 'تأكيد الحجز المجاني';

  @override
  String get sessionActionAcknowledgeSession => 'إقرار الجلسة';

  @override
  String get sessionActionStartSession => 'بدء الجلسة';

  @override
  String get sessionActionCompleteSession => 'إكمال الجلسة';

  @override
  String get sessionActionRequestReschedule => 'طلب إعادة الجدولة';

  @override
  String get sessionActionConfirmReschedule => 'تأكيد إعادة الجدولة';

  @override
  String get sessionActionAdminForceReschedule => 'إعادة جدولة إدارية';

  @override
  String get sessionActionCancelByStudent => 'إلغاء من الطالب';

  @override
  String get sessionActionCancelByTeacher => 'إلغاء من المعلم';

  @override
  String get sessionActionCancelByAdmin => 'إلغاء إداري';

  @override
  String get sessionActionMarkTeacherNoShow => 'تسجيل غياب المعلم';

  @override
  String get sessionActionMarkStudentNoShow => 'تسجيل غياب الطالب';

  @override
  String get sessionActionMarkBothNoShow => 'تسجيل غياب الطرفين';

  @override
  String get sessionActionMarkIncomplete => 'تسجيل عدم اكتمال';

  @override
  String get sessionActionOpenDispute => 'فتح نزاع';

  @override
  String get sessionActionIssueCompensation => 'إصدار تعويض';

  @override
  String get sessionActionIssueRefund => 'إصدار استرداد';

  @override
  String get sessionActionExpireReservation => 'انتهاء الحجز';

  @override
  String get sessionActionRejectBooking => 'رفض الحجز';

  @override
  String get bookingRequestSentTitle => 'تم إرسال طلب الحجز';

  @override
  String get bookingRequestSentSubtitle => 'بانتظار موافقة المعلم.';

  @override
  String get sessionAwaitingTeacherApproval => 'بانتظار موافقة المعلم';

  @override
  String get sessionAwaitingTeacherApprovalHint =>
      'سيقبل المعلم طلبك أو يرفضه. سنُبلّغك عند الرد.';

  @override
  String get sessionAwaitingReviewNextSteps =>
      'بانتظار موافقة المعلم.\nسيقبل المعلم طلب الحجز أو يرفضه.\nسنُبلّغك عند الرد.';

  @override
  String get paidSessionNoticeTitle => 'هذه الحصة مدفوعة';

  @override
  String get manualPaymentInstructionsBody =>
      'الدفع حاليًا يتم يدويًا عبر فودافون كاش أو إنستاباي أو تحويل بنكي، وذلك لحين الانتهاء من إضافة طرق الدفع أونلاين داخل التطبيق.';

  @override
  String get manualPaymentInstapayHandle => 'للدفع عبر إنستاباي:';

  @override
  String get manualPaymentInstapayLink => 'أو من خلال رابط الدفع:';

  @override
  String get manualPaymentRecipientMaskedName =>
      'اسم المستلم الظاهر عند التحويل:';

  @override
  String get manualPaymentReceiptWhatsappInstruction =>
      'بعد إتمام الدفع، يرجى إرسال صورة التحويل على واتساب إلى رقم الدعم:';

  @override
  String get manualPaymentConfirmationRule =>
      'سيتم تأكيد الحجز بعد مراجعة الدفع وتأكيد المعلم.';

  @override
  String get manualPaymentCancellationPolicy =>
      'إذا كنت قد أتممت الدفع يدويًا، يرجى التواصل مع الدعم لمراجعة حالة الدفع أو الاسترداد.';

  @override
  String manualPaymentCancellationSupportHint(String supportNumber) {
    return 'رقم الدعم: $supportNumber';
  }

  @override
  String get manualPaymentCopiedToClipboard => 'تم النسخ إلى الحافظة';

  @override
  String get paymentMethodVodafoneCash => 'Vodafone Cash';

  @override
  String get paymentMethodInstapay => 'InstaPay';

  @override
  String get paymentMethodBankTransfer => 'تحويل بنكي';

  @override
  String get bookingUnderReviewTitle => 'بانتظار موافقة المعلم';

  @override
  String get bookingUnderReviewPaymentHint =>
      'سيقبل المعلم طلب الحجز أو يرفضه.';

  @override
  String get bookingUnderReviewConfirmHint => 'سنُبلّغك عند رد المعلم.';

  @override
  String get bookingAcceptedTitle => 'تم قبول الحصة';

  @override
  String get bookingAcceptedSubtitle => 'يمكنك الانضمام في موعد الحصة';

  @override
  String get bookingRejectedTitle => 'اعتذر المحفظ عن قبول الحصة';

  @override
  String get bookingRejectedSubtitle => 'يمكنك اختيار موعد آخر';

  @override
  String get sendBookingRequest => 'إرسال طلب الحجز';

  @override
  String get sessionStatusBookingUnderReview => 'قيد المراجعة';

  @override
  String get sessionStatusRejectedByTutor => 'مرفوض';

  @override
  String teacherPendingBookingRequestsSection(int count) {
    return 'طلبات الحجز ($count)';
  }

  @override
  String get teacherPendingBookingRequestsSectionTitle => 'طلبات الحجز';

  @override
  String get upcomingSessionsSectionTitle => 'الحصص القادمة';

  @override
  String teacherDashboardShowAllSessions(int count) {
    return 'عرض الكل ($count)';
  }

  @override
  String get teacherDashboardShowLessSessions => 'عرض أقل';

  @override
  String get teacherPendingBookingRequestsEmptyTitle =>
      'لا توجد طلبات حجز حاليًا';

  @override
  String get teacherPendingBookingRequestsEmptySubtitle =>
      'ستظهر طلبات الطلاب هنا عند إرسالها';

  @override
  String get teacherDashboardLoadingLabel => 'جارٍ تحميل لوحتك';

  @override
  String get teacherDashboardRefreshingLabel => 'جارٍ التحديث';

  @override
  String get teacherDashboardSummaryTitle => 'نظرة سريعة';

  @override
  String get teacherDashboardStatPendingRequests => 'طلبات معلقة';

  @override
  String get teacherDashboardStatUpcomingSessions => 'حصص قادمة';

  @override
  String get teacherDashboardStatBookableSlotsThisWeek =>
      'مواعيد مفتوحة هذا الأسبوع';

  @override
  String get teacherDashboardStatBookableSlotsHorizon =>
      'مواعيد مفتوحة (14 يومًا)';

  @override
  String get teacherDashboardCategoriesTitle => 'أقسام لوحة المعلم';

  @override
  String get teacherDashboardCategoriesSubtitle =>
      'افتح قسمًا لعرض القائمة الكاملة والإجراءات.';

  @override
  String get teacherDashboardViewAsGrid => 'شبكة';

  @override
  String get teacherDashboardViewAsList => 'قائمة';

  @override
  String get teacherDashboardShowAsGrid => 'عرض كشبكة';

  @override
  String get teacherDashboardShowAsList => 'عرض كقائمة';

  @override
  String get teacherDashboardOpenCategory => 'فتح';

  @override
  String get teacherDashboardBookingRequestsCategorySubtitle =>
      'راجع طلبات الطلاب قبل انتهاء وقت الرد.';

  @override
  String get teacherDashboardUpcomingSessionsCategorySubtitle =>
      'انضم للحصص أو افتح التفاصيل أو أدِر التغييرات.';

  @override
  String get teacherDashboardBookableTimesCategorySubtitle =>
      'راجع المواعيد المفتوحة الناتجة من جدولك الأسبوعي.';

  @override
  String get teacherDashboardWeeklyScheduleSectionTitle => 'الجدول الأسبوعي';

  @override
  String get teacherDashboardWeeklyScheduleSectionSubtitle =>
      'ساعات عملك المتكررة تُنشئ المواعيد القابلة للحجز للطلاب.';

  @override
  String get teacherAcceptBookingRequest => 'قبول';

  @override
  String get teacherRejectBookingRequest => 'رفض';

  @override
  String get tutorRejectBookingSheetTitle => 'رفض طلب الحجز؟';

  @override
  String get tutorRejectBookingSheetBody =>
      'يمكنك توضيح سبب الرفض للطالب، أو رفض الطلب بدون سبب.';

  @override
  String get tutorRejectBookingReasonLabel => 'سبب الرفض';

  @override
  String get tutorRejectBookingReasonHint => 'مثال: الموعد غير مناسب';

  @override
  String get tutorRejectBookingConfirmAction => 'رفض الطلب';

  @override
  String get tutorRejectBookingGoBack => 'تراجع';

  @override
  String get tutorRejectBookingReasonTooLong => 'سبب الرفض طويل جداً';

  @override
  String get tutorCancelSessionFromCard => 'إلغاء';

  @override
  String get sessionLifecycleBookingUnderReview => 'بانتظار موافقة المعلم';

  @override
  String get sessionLifecycleRejectedByTutor => 'مرفوض من المحفظ';

  @override
  String get sessionActionSubmitBookingRequest => 'إرسال طلب الحجز';

  @override
  String get sessionActionAcceptBookingRequest => 'قبول طلب الحجز';

  @override
  String get sessionActionRejectBookingRequest => 'رفض طلب الحجز';

  @override
  String get sessionActionExpireBookingReview => 'انتهاء مراجعة الحجز';

  @override
  String sessionTimelineStatusTransition(String previous, String next) {
    return '$previous ← $next';
  }

  @override
  String get tutorDashboardStudentFallback => 'طالب';

  @override
  String get teacherDashboardLoadError => 'تعذّر تحميل الحصص، حاول مرة أخرى';

  @override
  String get tutorSessionStatusPendingApproval => 'بانتظار موافقتك';

  @override
  String get tutorSessionStatusAccepted => 'مقبولة';

  @override
  String get tutorSessionStatusRejected => 'مرفوضة';

  @override
  String get tutorSessionStatusCancelledByTutor => 'ألغيتها';

  @override
  String get tutorSessionStatusCancelledByStudent => 'ألغاها الطالب';

  @override
  String get tutorSessionStatusCompleted => 'مكتملة';

  @override
  String get tutorSessionStatusExpired => 'انتهى الموعد';

  @override
  String get tutorSessionJoinNotYet => 'لم يبدأ الموعد بعد';

  @override
  String tutorSessionDurationMinutes(int count) {
    return '$count د';
  }
}
