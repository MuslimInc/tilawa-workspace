import '../entities/email_registration_draft.dart';
import '../entities/email_registration_step.dart';
import 'email_auth_form_policy.dart';

/// Per-step validation for the multi-step email registration wizard.
abstract final class EmailRegistrationFormPolicy {
  static const String displayNameRequired = 'registrationDisplayNameRequired';
  static const String preferredLanguageRequired =
      'registrationPreferredLanguageRequired';

  static Map<String, String?> validateStep({
    required EmailRegistrationStep step,
    required EmailRegistrationDraft draft,
  }) {
    return switch (step) {
      EmailRegistrationStep.account => _validateAccount(draft),
      EmailRegistrationStep.personal => _validatePersonal(draft),
      EmailRegistrationStep.review => validateAll(draft: draft),
    };
  }

  static Map<String, String?> validateAll({
    required EmailRegistrationDraft draft,
  }) {
    return <String, String?>{
      ..._validateAccount(draft),
      ..._validatePersonal(draft),
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
      'preferredLanguage': draft.preferredLanguageCode == null
          ? preferredLanguageRequired
          : null,
    };
  }

  static bool isStepValid({
    required EmailRegistrationStep step,
    required EmailRegistrationDraft draft,
  }) {
    final Map<String, String?> errors = validateStep(
      step: step,
      draft: draft,
    );
    return errors.values.every((String? value) => value == null);
  }
}
