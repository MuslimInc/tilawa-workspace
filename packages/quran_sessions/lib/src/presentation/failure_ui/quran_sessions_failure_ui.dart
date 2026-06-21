import 'package:flutter/widgets.dart';

import '../../domain/failures/quran_sessions_failure.dart';

/// Extension that converts a typed [QuranSessionsFailure] into a
/// user-facing, localised message.
///
/// The **default** implementation returns Arabic developer-facing strings so
/// the package is self-contained during development.
///
/// The host app MUST override this by defining its own extension in the
/// app's l10n layer:
///
/// ```dart
/// // In apps/tilawa/lib/core/extensions/failure_l10n.dart
/// extension TilawaFailureL10n on QuranSessionsFailure {
///   @override
///   String toLocalizedMessage(BuildContext context) => switch (this) {
///     NetworkFailure()         => context.l10n.errorNetwork,
///     ...
///   };
/// }
/// ```
///
/// Screens call: `state.failure.toLocalizedMessage(context)`
/// Neither BLoCs nor states ever produce a String.
extension QuranSessionsFailureUi on QuranSessionsFailure {
  String toLocalizedMessage(BuildContext context) => switch (this) {
    // ── Network / transport ─────────────────────────────────────────────────
    NetworkFailure() => 'لا يوجد اتصال بالإنترنت.',
    TimeoutFailure() => 'انتهت مهلة الطلب. يرجى المحاولة مجدداً.',

    // ── Server / HTTP ───────────────────────────────────────────────────────
    ServerFailure(statusCode: final c) when c == 401 =>
      'انتهت الجلسة. يرجى تسجيل الدخول مجدداً.',
    ServerFailure(statusCode: final c) when c == 403 =>
      'ليس لديك صلاحية لتنفيذ هذا الإجراء.',
    ServerFailure() => 'حدث خطأ في الخادم. يرجى المحاولة لاحقاً.',
    UnauthorizedFailure() => 'غير مخوّل للقيام بهذا الإجراء.',

    // ── Domain / resource ───────────────────────────────────────────────────
    NotFoundFailure(resourceType: final t) => '$t غير موجود.',
    ValidationFailure(field: final f, code: final c) =>
      'خطأ في التحقق: $f ($c).',

    // ── Booking ─────────────────────────────────────────────────────────────
    SlotUnavailableFailure() =>
      'هذا الموعد لم يعد متاحاً. يرجى اختيار موعد آخر.',
    BookingConflictFailure() => 'لديك جلسة أخرى في نفس الوقت.',

    // ── Profile / eligibility ───────────────────────────────────────────────
    ProfileIncompleteFailure(missingFields: final fields) =>
      'ملفك الشخصي غير مكتمل. '
          'المعلومات المطلوبة: ${fields.map(_fieldAr).join('، ')}.',

    GenderNotAllowedFailure(
      teacherGender: final tg,
      studentGender: final sg,
    ) =>
      'لا يمكن الحجز: '
          'هذا المعلم (${_genderAr(tg)}) لا يقبل الطلاب '
          '${_genderAr(sg, asStudent: true)} وفق السياسة الحالية.',

    AgeNotAllowedFailure(studentAgeGroup: final ag) =>
      ag == 'child'
          ? 'هذا المعلم لا يقبل الطلاب الأطفال.'
          : 'فئتك العمرية غير مقبولة لدى هذا المعلم.',

    TeacherNotVerifiedFailure() =>
      'لم يتم توثيق هذا المعلم بعد ولا يمكن حجز جلسة معه.',

    AccountBlockedFailure(reason: final r) =>
      r != null
          ? 'حسابك موقوف بسبب: ${_restrictionReasonAr(r)}.'
          : 'حسابك موقوف. يرجى التواصل مع الدعم.',

    GuardianApprovalRequiredFailure() =>
      'يتطلب الحجز لهذا الطالب موافقة وليّ الأمر أولاً.',

    PolicyViolationFailure(policyName: final p, detail: final d) =>
      'الحجز مرفوض لمخالفة سياسة "$p": $d.',

    // ── Market / location ───────────────────────────────────────────────────
    MarketNotEnabledFailure(cityId: final c) =>
      c != null
          ? 'خدمة الجلسات غير متاحة في مدينتك حالياً. جرّب مدينة أخرى.'
          : 'خدمة الجلسات غير متاحة في دولتك حالياً.',

    TeacherNotInMarketFailure() =>
      'هذا المعلم غير متاح في منطقتك. يرجى اختيار معلم آخر.',

    // ── Teacher application ─────────────────────────────────────────────────
    TeacherApplicationNotFoundFailure() => 'لم يتم العثور على طلب تسجيل كمعلم.',
    TeacherApplicationAlreadyPendingFailure() =>
      'لديك طلب معلم قيد المراجعة بالفعل.',
    TeacherApplicationRejectedFailure() =>
      'تم رفض طلبك. يمكنك إعادة التقديم بعد انتهاء فترة الانتظار.',
    TeacherApplicationSuspendedFailure() => 'حسابك كمعلم موقوف مؤقتاً.',
    TeacherApplicationRevokedFailure() => 'تم إلغاء حسابك كمعلم بشكل نهائي.',
    TeacherPhoneNumberRequiredFailure() =>
      'رقم الهاتف مطلوب لإتمام طلب التسجيل كمعلم.',
    InvalidTeacherPhoneNumberFailure() =>
      'رقم الهاتف غير صحيح. يرجى إدخال رقم بصيغة دولية صحيحة.',
    PhoneCountryMismatchFailure() =>
      'رقم الهاتف لا يطابق الدولة المختارة.',
    TeacherApplicationIncompleteFailure(reason: final r) =>
      'طلب التسجيل غير مكتمل: $r',
    ReapplicationTooSoonFailure(cooldownEndsAt: final d) =>
      'لا يمكنك إعادة التقديم قبل ${d.day}/${d.month}/${d.year}.',

    // ── Teacher profile ─────────────────────────────────────────────────────
    TeacherProfileNotApprovedFailure() => 'لم تتم الموافقة على ملف المعلم بعد.',
    TeacherProfileNotActiveFailure() => 'ملف المعلم غير نشط حالياً.',

    // ── Payment ─────────────────────────────────────────────────────────────
    PaymentDeclinedFailure() => 'تم رفض الدفع. يرجى استخدام طريقة دفع أخرى.',
    PaymentCancelledFailure() => 'تم إلغاء عملية الدفع.',
    PaymentProviderFailure() => 'تعذّرت معالجة الدفع. يرجى المحاولة مجدداً.',

    // ── Storage ─────────────────────────────────────────────────────────────
    CacheFailure() => 'تعذّرت قراءة البيانات المحلية.',

    // ── Catch-all ───────────────────────────────────────────────────────────
    UnknownFailure() => 'حدث خطأ غير متوقع.',
  };
}

// ── Label helpers (Arabic) ────────────────────────────────────────────────────

String _fieldAr(String field) => switch (field) {
  'gender' => 'الجنس',
  'dateOfBirth' => 'تاريخ الميلاد',
  'displayName' => 'الاسم الكامل',
  'countryCode' => 'الدولة',
  'cityId' => 'المدينة',
  _ => field,
};

String _genderAr(String gender, {bool asStudent = false}) => switch (gender) {
  'male' => asStudent ? 'الذكور' : 'ذكر',
  'female' => asStudent ? 'الإناث' : 'أنثى',
  _ => gender,
};

String _restrictionReasonAr(String reason) => switch (reason) {
  'falseIdentity' => 'بيانات هوية مزيفة',
  'policyViolation' => 'مخالفة السياسات',
  'safetyConcern' => 'مخاوف تتعلق بالسلامة',
  'abuseReport' => 'بلاغ إساءة',
  'repeatedNoShow' => 'غياب متكرر',
  'adminDecision' => 'قرار إداري',
  _ => reason,
};
