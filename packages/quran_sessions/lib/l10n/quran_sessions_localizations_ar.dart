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
  String get guardianApprovalRequired =>
      'يتطلب الحجز لهذا الطالب موافقة وليّ الأمر أولاً.';

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
  String get profileFieldGender => 'الجنس';

  @override
  String get profileFieldDateOfBirth => 'تاريخ الميلاد';

  @override
  String get profileFieldCountry => 'الدولة';

  @override
  String get profileFieldCity => 'المدينة';

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
  String get quranSessionsHomeTitle => 'تعلم قراءة القرآن';

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
      'انضم إلى نخبة المعلمين المعتمدين على تلاوة';

  @override
  String get teacherListTitle => 'ابحث عن معلم';

  @override
  String noTeachersForSpecialization(String specialization) {
    return 'لم يتم العثور على معلمين لـ \"$specialization\"';
  }

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
  String get reviewSubmittedThanks => 'شكراً — تم إرسال تقييمك!';

  @override
  String upcomingSessionsSection(int count) {
    return 'القادمة ($count)';
  }

  @override
  String get noUpcomingSessions => 'لا توجد جلسات قادمة';

  @override
  String pastSessionsSection(int count) {
    return 'السابقة ($count)';
  }

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
  String get cancelPolicyFree => 'هذه جلسة مجانية. لا يوجد استرداد.';

  @override
  String get cancelPolicyFullRefund => 'ستحصل على استرداد كامل إذا ألغيت الآن.';

  @override
  String get cancelPolicyPartialRefund =>
      'قد ينطبق استرداد جزئي وفق سياسة الإلغاء.';

  @override
  String get cancelPolicyNoRefund => 'لا ينطبق استرداد للإلغاء في هذا الوقت.';

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
  String get rescheduleAction => 'إعادة الجدولة';

  @override
  String get sessionDetailTitle => 'تفاصيل الجلسة';

  @override
  String get sessionTimelineTitle => 'سجل النشاط';

  @override
  String get sessionTimelineEmpty => 'لا يوجد نشاط مسجل بعد.';

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
  String get bookSessionAction => 'احجز جلسة';

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
  String get noSlotsAvailable => 'لا توجد مواعيد متاحة';

  @override
  String get noSlotsAvailableThisDay => 'لا توجد مواعيد متاحة في هذا اليوم';

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
  String get upcomingSessionsEmptyTitle => 'لا توجد جلسات قادمة';

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
  String get becomeTeacherOnTilawa => 'أصبح محفظًا على تلاوة';

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
      'يقوم فريق تلاوة بمراجعة طلبك. سنتواصل معك قريبًا.';

  @override
  String get applicationStatusApprovedTitle => 'تهانينا! تمت الموافقة';

  @override
  String get applicationStatusApprovedSubtitle =>
      'أصبحت محفظًا معتمدًا على منصة تلاوة.';

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
}
