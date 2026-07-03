import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/domain/entities/email_registration_draft.dart';
import 'package:tilawa/features/auth/domain/entities/email_registration_step.dart';
import 'package:tilawa/features/auth/domain/policies/email_registration_form_policy.dart';

void main() {
  EmailRegistrationDraft validAdultDraft() => EmailRegistrationDraft(
    email: 'user@example.com',
    password: 'secret1',
    confirmPassword: 'secret1',
    displayName: 'Test User',
    gender: 'male',
    dateOfBirth: DateTime(1990, 1, 1),
    countryCode: 'EG',
    countryName: 'Egypt',
    cityId: 'cairo',
    cityName: 'Cairo',
    currencyCode: 'EGP',
    timezone: 'Africa/Cairo',
    preferredLanguageCode: 'ar',
    learningGoals: <String>['recitation'],
  );

  group('EmailRegistrationFormPolicy', () {
    test('account step rejects invalid email', () {
      final Map<String, String?> errors =
          EmailRegistrationFormPolicy.validateStep(
            step: EmailRegistrationStep.account,
            draft: const EmailRegistrationDraft(email: 'bad'),
            requiresGuardianStep: false,
          );

      expect(errors['email'], isNotNull);
    });

    test('personal step requires display name and location', () {
      final Map<String, String?> errors =
          EmailRegistrationFormPolicy.validateStep(
            step: EmailRegistrationStep.personal,
            draft: const EmailRegistrationDraft(),
            requiresGuardianStep: false,
          );

      expect(errors['displayName'], isNotNull);
      expect(errors['gender'], isNotNull);
      expect(errors['country'], isNotNull);
      expect(errors['city'], isNotNull);
    });

    test('guardian step required only for minors', () {
      expect(
        EmailRegistrationFormPolicy.requiresGuardianStep(
          dateOfBirth: DateTime(2018, 1, 1),
          childAgeThreshold: 13,
        ),
        isTrue,
      );
      expect(
        EmailRegistrationFormPolicy.requiresGuardianStep(
          dateOfBirth: DateTime(1990, 1, 1),
          childAgeThreshold: 13,
        ),
        isFalse,
      );
    });

    test('validateAll passes for complete adult draft', () {
      final bool valid = EmailRegistrationFormPolicy.isStepValid(
        step: EmailRegistrationStep.review,
        draft: validAdultDraft(),
        requiresGuardianStep: false,
      );

      expect(valid, isTrue);
    });

    test('guardian consent required when guardian step applies', () {
      final EmailRegistrationDraft childDraft = validAdultDraft().copyWith(
        dateOfBirth: DateTime(2018, 1, 1),
      );
      final Map<String, String?> errors =
          EmailRegistrationFormPolicy.validateStep(
            step: EmailRegistrationStep.guardian,
            draft: childDraft,
            requiresGuardianStep: true,
          );

      expect(errors['guardianConsent'], isNotNull);
    });
  });

  group('EmailRegistrationStepX', () {
    test('skips guardian step for adults', () {
      final EmailRegistrationStep? next = EmailRegistrationStep.quranLearning
          .next(includesGuardian: false);

      expect(next, EmailRegistrationStep.review);
    });

    test('back from review skips guardian for adults', () {
      final EmailRegistrationStep? previous = EmailRegistrationStep.review
          .previous(includesGuardian: false);

      expect(previous, EmailRegistrationStep.quranLearning);
    });
  });
}
