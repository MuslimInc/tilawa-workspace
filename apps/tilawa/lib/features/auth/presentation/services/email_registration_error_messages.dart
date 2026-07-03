import 'package:tilawa/l10n/generated/app_localizations.dart';

import '../../domain/policies/email_registration_form_policy.dart';
import 'email_auth_error_messages.dart';

/// Maps registration field error keys to localized strings.
String? localizedRegistrationFieldError(
  String? key,
  AppLocalizations l10n,
) {
  if (key == null) {
    return null;
  }

  if (key == EmailRegistrationFormPolicy.displayNameRequired) {
    return l10n.registrationDisplayNameRequired;
  }
  if (key == EmailRegistrationFormPolicy.preferredLanguageRequired) {
    return l10n.registrationPreferredLanguageRequired;
  }

  return localizedEmailAuthFieldError(key, l10n);
}
