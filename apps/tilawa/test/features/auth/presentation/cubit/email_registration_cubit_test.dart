import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/domain/entities/email_auth_failure_key.dart';
import 'package:tilawa/features/auth/domain/entities/email_registration_step.dart';
import 'package:tilawa/features/auth/presentation/cubit/email_registration_cubit.dart';
import 'package:tilawa/features/auth/presentation/cubit/email_registration_state.dart';

import '../bloc/auth_bloc_test.mocks.dart';

void main() {
  late EmailRegistrationCubit cubit;
  late MockRegisterWithEmailUseCase registerWithEmail;

  setUp(() {
    registerWithEmail = MockRegisterWithEmailUseCase();
    cubit = EmailRegistrationCubit(registerWithEmail);
  });

  tearDown(() async {
    await cubit.close();
  });

  blocTest<EmailRegistrationCubit, EmailRegistrationState>(
    'advances from account to personal when account step is valid',
    build: () => cubit,
    act: (EmailRegistrationCubit c) {
      c
        ..emailChanged('user@example.com')
        ..passwordChanged('secret1')
        ..confirmPasswordChanged('secret1')
        ..goNext();
    },
    verify: (EmailRegistrationCubit c) {
      expect(c.state.currentStep, EmailRegistrationStep.personal);
    },
  );

  blocTest<EmailRegistrationCubit, EmailRegistrationState>(
    'advances from personal to review when basic profile is valid',
    build: () => cubit,
    act: (EmailRegistrationCubit c) {
      c
        ..displayNameChanged('Saved Name')
        ..preferredLanguageSelected('ar')
        ..goNext();
    },
    seed: () => const EmailRegistrationState(
      currentStep: EmailRegistrationStep.personal,
    ),
    verify: (EmailRegistrationCubit c) {
      expect(c.state.currentStep, EmailRegistrationStep.review);
    },
  );

  blocTest<EmailRegistrationCubit, EmailRegistrationState>(
    'back preserves draft data',
    build: () => cubit,
    act: (EmailRegistrationCubit c) {
      c
        ..emailChanged('user@example.com')
        ..passwordChanged('secret1')
        ..confirmPasswordChanged('secret1')
        ..goNext()
        ..displayNameChanged('Saved Name')
        ..goBack();
    },
    verify: (EmailRegistrationCubit c) {
      expect(c.state.currentStep, EmailRegistrationStep.account);
      expect(c.state.draft.email, 'user@example.com');
      expect(c.state.draft.displayName, 'Saved Name');
    },
  );

  blocTest<EmailRegistrationCubit, EmailRegistrationState>(
    'account step validation surfaces email error',
    build: () => cubit,
    act: (EmailRegistrationCubit c) {
      c.emailChanged('bad');
      c.goNext();
    },
    verify: (EmailRegistrationCubit c) {
      expect(c.state.currentStep, EmailRegistrationStep.account);
      expect(c.state.fieldError('email'), isNotNull);
    },
  );

  blocTest<EmailRegistrationCubit, EmailRegistrationState>(
    'registration auth failure returns to account step with email error',
    build: () => cubit,
    seed: () => const EmailRegistrationState(
      currentStep: EmailRegistrationStep.review,
    ),
    act: (EmailRegistrationCubit c) {
      c.onRegistrationAuthFailed(
        emailErrorKey: EmailAuthFailureKey.emailAlreadyInUseWithGoogle,
      );
    },
    verify: (EmailRegistrationCubit c) {
      expect(c.state.currentStep, EmailRegistrationStep.account);
      expect(c.state.status, EmailRegistrationStatus.editing);
      expect(
        c.state.fieldError('email'),
        EmailAuthFailureKey.emailAlreadyInUseWithGoogle,
      );
    },
  );
}
