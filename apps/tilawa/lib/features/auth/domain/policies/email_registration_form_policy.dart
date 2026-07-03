import '../entities/email_registration_draft.dart';
import '../entities/email_registration_step.dart';
import 'email_auth_form_policy.dart';

/// Per-step validation for the multi-step email registration wizard.
abstract final class EmailRegistrationFormPolicy {
  static const String displayNameRequired = 'registrationDisplayNameRequired';
  static const String genderRequired = 'registrationGenderRequired';
  static const String dateOfBirthRequired = 'registrationDateOfBirthRequired';
  static const String countryRequired = 'registrationCountryRequired';
  static const String cityRequired = 'registrationCityRequired';
  static const String preferredLanguageRequired =
      'registrationPreferredLanguageRequired';
  static const String learningGoalsRequired =
      'registrationLearningGoalsRequired';
  static const String guardianConsentRequired =
      'registrationGuardianConsentRequired';

  static Map<String, String?> validateStep({
    required EmailRegistrationStep step,
    required EmailRegistrationDraft draft,
    required bool requiresGuardianStep,
  }) {
    return switch (step) {
      EmailRegistrationStep.account => _validateAccount(draft),
      EmailRegistrationStep.personal => _validatePersonal(draft),
      EmailRegistrationStep.quranLearning => _validateLearning(draft),
      EmailRegistrationStep.guardian =>
        requiresGuardianStep
            ? _validateGuardian(draft)
            : const <String, String?>{},
      EmailRegistrationStep.review => validateAll(
        draft: draft,
        requiresGuardianStep: requiresGuardianStep,
      ),
    };
  }

  static Map<String, String?> validateAll({
    required EmailRegistrationDraft draft,
    required bool requiresGuardianStep,
  }) {
    return <String, String?>{
      ..._validateAccount(draft),
      ..._validatePersonal(draft),
      ..._validateLearning(draft),
      if (requiresGuardianStep) ..._validateGuardian(draft),
    };
  }

  static Map<String, String?> _validateAccount(EmailRegistrationDraft draft) {
    return <String, String?>{
      'email': EmailAuthFormPolicy.validateEmail(draft.email),
      'password': EmailAuthFormPolicy.validatePassword(draft.password),
      'confirmPassword': EmailAuthFormPolicy.validateConfirmPassword(
        password: draft.password,
        confirmPassword: draft.confirmPassword,
      ),
    };
  }

  static Map<String, String?> _validatePersonal(EmailRegistrationDraft draft) {
    return <String, String?>{
      'displayName': draft.displayName.trim().isEmpty
          ? displayNameRequired
          : null,
      'gender': draft.gender == null ? genderRequired : null,
      'dateOfBirth': draft.dateOfBirth == null ? dateOfBirthRequired : null,
      'country': draft.countryCode == null ? countryRequired : null,
      'city': draft.cityId == null ? cityRequired : null,
      'preferredLanguage': draft.preferredLanguageCode == null
          ? preferredLanguageRequired
          : null,
    };
  }

  static Map<String, String?> _validateLearning(EmailRegistrationDraft draft) {
    return <String, String?>{
      'learningGoals': draft.learningGoals.isEmpty
          ? learningGoalsRequired
          : null,
    };
  }

  static Map<String, String?> _validateGuardian(EmailRegistrationDraft draft) {
    return <String, String?>{
      'guardianConsent': draft.guardianConsentAcknowledged
          ? null
          : guardianConsentRequired,
    };
  }

  static bool isStepValid({
    required EmailRegistrationStep step,
    required EmailRegistrationDraft draft,
    required bool requiresGuardianStep,
  }) {
    final Map<String, String?> errors = validateStep(
      step: step,
      draft: draft,
      requiresGuardianStep: requiresGuardianStep,
    );
    return errors.values.every((String? value) => value == null);
  }

  static bool requiresGuardianStep({
    required DateTime? dateOfBirth,
    required int childAgeThreshold,
  }) {
    if (dateOfBirth == null) {
      return false;
    }
    final DateTime today = DateTime.now();
    var age = today.year - dateOfBirth.year;
    final bool birthdayPassed =
        today.month > dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day >= dateOfBirth.day);
    if (!birthdayPassed) {
      age--;
    }
    return age < childAgeThreshold;
  }
}
