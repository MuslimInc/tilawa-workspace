import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/domain/entities/email_registration_draft.dart';
import 'package:tilawa/features/auth/domain/entities/email_registration_step.dart';
import 'package:tilawa/features/auth/domain/policies/email_registration_form_policy.dart';

void main() {
  EmailRegistrationDraft validDraft() => const EmailRegistrationDraft(
    email: 'user@example.com',
    password: 'secret1',
    confirmPassword: 'secret1',
    displayName: 'Test User',
    preferredLanguageCode: 'ar',
  );

  group('EmailRegistrationFormPolicy', () {
    test('account step rejects invalid email', () {
      final Map<String, String?> errors =
          EmailRegistrationFormPolicy.validateStep(
            step: EmailRegistrationStep.account,
            draft: const EmailRegistrationDraft(email: 'bad'),
          );

      expect(errors['email'], isNotNull);
    });

    test('personal step requires display name and language only', () {
      final Map<String, String?> errors =
          EmailRegistrationFormPolicy.validateStep(
            step: EmailRegistrationStep.personal,
            draft: const EmailRegistrationDraft(),
          );

      expect(errors['displayName'], isNotNull);
      expect(errors['preferredLanguage'], isNotNull);
      expect(errors.containsKey('gender'), isFalse);
      expect(errors.containsKey('country'), isFalse);
      expect(errors.containsKey('learningGoals'), isFalse);
    });

    test('validateAll passes for complete draft without quran fields', () {
      final bool valid = EmailRegistrationFormPolicy.isStepValid(
        step: EmailRegistrationStep.review,
        draft: validDraft(),
      );

      expect(valid, isTrue);
    });
  });

  group('EmailRegistrationStepX', () {
    test('has three visible steps', () {
      expect(EmailRegistrationStepX.visibleStepCount(), 3);
    });

    test('advances account to personal to review', () {
      expect(
        EmailRegistrationStep.account.next(),
        EmailRegistrationStep.personal,
      );
      expect(
        EmailRegistrationStep.personal.next(),
        EmailRegistrationStep.review,
      );
      expect(EmailRegistrationStep.review.next(), isNull);
    });
  });
}
