// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

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
  String get teacherNotInMarket =>
      'هذا المعلم غير متاح في منطقتك. يرجى اختيار معلم آخر.';

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
}
