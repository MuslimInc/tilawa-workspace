import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/config/language_config.dart';

import '../../domain/entities/email_registration_draft.dart';
import '../../domain/entities/email_registration_step.dart';
import '../../domain/entities/register_with_email_result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/policies/email_registration_form_policy.dart';
import '../../domain/usecases/register_with_email_use_case.dart';
import 'email_registration_state.dart';

@injectable
class EmailRegistrationCubit extends Cubit<EmailRegistrationState> {
  EmailRegistrationCubit(this._registerWithEmail)
    : super(
        const EmailRegistrationState(
          draft: EmailRegistrationDraft(
            preferredLanguageCode: LanguageConfig.defaultLanguageCode,
          ),
        ),
      );

  final RegisterWithEmailUseCase _registerWithEmail;

  void emailChanged(String value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(email: value),
        fieldErrors: _clearFieldError('email'),
      ),
    );
  }

  void passwordChanged(String value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(password: value),
        fieldErrors: _clearFieldErrors(<String>['password', 'confirmPassword']),
      ),
    );
  }

  void confirmPasswordChanged(String value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(confirmPassword: value),
        fieldErrors: _clearFieldError('confirmPassword'),
      ),
    );
  }

  void displayNameChanged(String value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(displayName: value),
        fieldErrors: _clearFieldError('displayName'),
      ),
    );
  }

  void preferredLanguageSelected(String languageCode) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(preferredLanguageCode: languageCode),
        fieldErrors: _clearFieldError('preferredLanguage'),
      ),
    );
  }

  /// Validates the current step; callers read
  /// [EmailRegistrationState.isCurrentStepValid].
  void validateCurrentStep() {
    final Map<String, String?> errors =
        EmailRegistrationFormPolicy.validateStep(
          step: state.currentStep,
          draft: state.draft,
        );
    emit(state.copyWith(fieldErrors: errors));
  }

  void goBack() {
    if (!state.canGoBack) {
      return;
    }
    final EmailRegistrationStep? previous = state.currentStep.previous();
    if (previous == null) {
      return;
    }
    emit(
      state.copyWith(
        currentStep: previous,
        clearFieldErrors: true,
      ),
    );
  }

  void goNext() {
    validateCurrentStep();
    if (!state.isCurrentStepValid) {
      return;
    }
    final EmailRegistrationStep? next = state.currentStep.next();
    if (next == null) {
      return;
    }
    emit(
      state.copyWith(
        currentStep: next,
        clearFieldErrors: true,
      ),
    );
  }

  void onRegistrationAuthFailed({String? emailErrorKey}) {
    final Map<String, String?> fieldErrors = emailErrorKey == null
        ? state.fieldErrors
        : <String, String?>{
            ...state.fieldErrors,
            'email': emailErrorKey,
          };
    emit(
      state.copyWith(
        status: EmailRegistrationStatus.editing,
        currentStep: EmailRegistrationStep.account,
        fieldErrors: fieldErrors,
      ),
    );
  }

  void markProfilePersistenceFailed(UserEntity user) {
    emit(
      state.copyWith(
        status: EmailRegistrationStatus.profilePersistenceFailed,
        authenticatedUser: user,
      ),
    );
  }

  void clearProfilePersistenceFailure() {
    emit(
      state.copyWith(
        status: EmailRegistrationStatus.editing,
        clearAuthenticatedUser: true,
      ),
    );
  }

  /// Retries persisting the profile; callers observe the outcome via
  /// [EmailRegistrationState.status] and
  /// [EmailRegistrationState.authenticatedUser].
  Future<void> retryProfilePersistence() async {
    final UserEntity? user = state.authenticatedUser;
    if (user == null) {
      return;
    }
    emit(state.copyWith(status: EmailRegistrationStatus.submitting));
    final RegisterWithEmailResult result = await _registerWithEmail
        .retryProfilePersistence(
          user: user,
          draft: state.draft,
        );

    if (isClosed) return;

    switch (result) {
      case RegisterWithEmailCompleted():
        emit(
          state.copyWith(
            status: EmailRegistrationStatus.editing,
            clearAuthenticatedUser: true,
          ),
        );
      case RegisterWithEmailAuthFailed():
        emit(state.copyWith(status: EmailRegistrationStatus.editing));
      case RegisterWithEmailProfilePersistenceFailed(:final user):
        emit(
          state.copyWith(
            status: EmailRegistrationStatus.profilePersistenceFailed,
            authenticatedUser: user,
          ),
        );
    }
  }

  Map<String, String?> _clearFieldError(String key) {
    final Map<String, String?> next = Map<String, String?>.from(
      state.fieldErrors,
    );
    next.remove(key);
    return next;
  }

  Map<String, String?> _clearFieldErrors(List<String> keys) {
    final Map<String, String?> next = Map<String, String?>.from(
      state.fieldErrors,
    );
    for (final String key in keys) {
      next.remove(key);
    }
    return next;
  }
}
