import 'package:equatable/equatable.dart';

import '../../domain/entities/email_registration_draft.dart';
import '../../domain/entities/email_registration_step.dart';
import '../../domain/entities/user_entity.dart';

enum EmailRegistrationStatus {
  editing,
  submitting,
  profilePersistenceFailed,
}

class EmailRegistrationState extends Equatable {
  const EmailRegistrationState({
    this.status = EmailRegistrationStatus.editing,
    this.currentStep = EmailRegistrationStep.account,
    this.draft = const EmailRegistrationDraft(),
    this.fieldErrors = const <String, String?>{},
    this.authenticatedUser,
  });

  final EmailRegistrationStatus status;
  final EmailRegistrationStep currentStep;
  final EmailRegistrationDraft draft;
  final Map<String, String?> fieldErrors;
  final UserEntity? authenticatedUser;

  int get visibleStepCount => EmailRegistrationStepX.visibleStepCount();

  int get currentStepDisplayIndex => currentStep.displayIndex;

  bool get isSubmitting => status == EmailRegistrationStatus.submitting;

  bool get canGoBack => currentStep != EmailRegistrationStep.account;

  String? fieldError(String key) => fieldErrors[key];

  EmailRegistrationState copyWith({
    EmailRegistrationStatus? status,
    EmailRegistrationStep? currentStep,
    EmailRegistrationDraft? draft,
    Map<String, String?>? fieldErrors,
    bool clearFieldErrors = false,
    UserEntity? authenticatedUser,
    bool clearAuthenticatedUser = false,
  }) {
    return EmailRegistrationState(
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      draft: draft ?? this.draft,
      fieldErrors: clearFieldErrors
          ? const <String, String?>{}
          : (fieldErrors ?? this.fieldErrors),
      authenticatedUser: clearAuthenticatedUser
          ? null
          : (authenticatedUser ?? this.authenticatedUser),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    currentStep,
    draft,
    fieldErrors,
    authenticatedUser,
  ];
}
