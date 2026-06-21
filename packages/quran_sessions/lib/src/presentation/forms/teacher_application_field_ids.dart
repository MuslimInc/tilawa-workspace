/// Stable field ids for teacher application scroll-to-error anchors.
abstract final class TeacherApplicationFieldIds {
  static const String phone = 'teacher.phone';
  static const String teachingLanguages = 'teacher.teachingLanguages';
  static const String specializations = 'teacher.specializations';
  static const String bio = 'teacher.bio';
}

/// Arabic copy for teacher application submit-time validation (UI guidance).
abstract final class TeacherApplicationValidationMessages {
  static const String phoneRequired = 'رقم الهاتف مطلوب';
  static const String phoneInvalid = 'رقم الهاتف غير صحيح';
  static const String phoneCountryMismatch =
      'رقم الهاتف لا يطابق الدولة المختارة';
  static const String teachingLanguagesRequired =
      'اختر لغة تدريس واحدة على الأقل';
  static const String specializationsRequired = 'اختر تخصصاً واحداً على الأقل';
  static const String bioRequired = 'النبذة التعريفية مطلوبة';
}
