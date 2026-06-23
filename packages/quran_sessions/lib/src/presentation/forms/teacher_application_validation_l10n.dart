import '../../../l10n/quran_sessions_localizations.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../../domain/value_objects/teacher_public_name.dart';
import 'teacher_application_field_ids.dart';

/// Stable validation codes stored in [TeacherApplicationEditing] state.
abstract final class TeacherApplicationValidationCodes {
  static const phoneRequired = 'phoneRequired';
  static const phoneInvalid = 'phoneInvalid';
  static const phoneCountryMismatch = 'phoneCountryMismatch';
  static const teachingLanguagesRequired = 'teachingLanguagesRequired';
  static const specializationsRequired = 'specializationsRequired';
  static const bioRequired = 'bioRequired';
}

extension TeacherApplicationValidationL10n on QuranSessionsLocalizations {
  String messageForValidationCode(String code) => switch (code) {
    TeacherApplicationValidationCodes.phoneRequired => teacherPhoneRequired,
    TeacherApplicationValidationCodes.phoneInvalid => invalidTeacherPhone,
    TeacherApplicationValidationCodes.phoneCountryMismatch =>
      phoneCountryMismatch,
    TeacherApplicationValidationCodes.teachingLanguagesRequired =>
      teachingLanguagesRequired,
    TeacherApplicationValidationCodes.specializationsRequired =>
      specializationsRequired,
    TeacherApplicationValidationCodes.bioRequired => bioRequired,
    _ => code,
  };

  String messageForPublicNameFailure(ValidationFailure failure) {
    if (failure.field != ValidateTeacherPublicName.field) {
      return validationError(failure.code, failure.field);
    }
    return switch (failure.code) {
      'required' => teacherPublicNameRequired,
      'placeholder' => teacherPublicNamePlaceholderNotAllowed,
      'too_short' || 'invalid' => teacherPublicNameInvalid,
      _ => teacherPublicNameInvalid,
    };
  }
}

extension TeacherApplicationFieldValidationL10n on QuranSessionsLocalizations {
  String? messageForFieldError(String fieldId, String? code) {
    if (code == null) return null;
    if (fieldId == TeacherApplicationFieldIds.publicDisplayName) {
      return messageForPublicNameFailure(
        ValidationFailure(field: ValidateTeacherPublicName.field, code: code),
      );
    }
    return messageForValidationCode(code);
  }
}
