import 'package:equatable/equatable.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../domain/entities/teacher_application.dart';
import '../../../domain/failures/quran_sessions_failure.dart';
import '../../../domain/value_objects/teacher_public_name.dart';
import '../../../utils/phone_normalizer.dart';
import '../../forms/teacher_application_field_ids.dart';
import '../../forms/teacher_application_validation_l10n.dart';

sealed class TeacherApplicationState extends Equatable {
  const TeacherApplicationState();

  @override
  List<Object?> get props => [];
}

final class TeacherApplicationInitial extends TeacherApplicationState {
  const TeacherApplicationInitial();
}

final class TeacherApplicationLoading extends TeacherApplicationState {
  const TeacherApplicationLoading();
}

/// No application exists yet — user sees the "Start Application" CTA.
final class TeacherApplicationNotStarted extends TeacherApplicationState {
  const TeacherApplicationNotStarted({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Draft application in progress — user is filling the form.
final class TeacherApplicationEditing extends TeacherApplicationState {
  const TeacherApplicationEditing({
    required this.application,
    this.phoneRaw = '',
    this.publicDisplayNameRaw = '',
    this.prefillPublicDisplayName,
    this.phoneErrorCode,
    this.publicDisplayNameErrorCode,
    this.phoneInteracted = false,
    this.publicDisplayNameInteracted = false,
    this.submitAttempted = false,
    this.submitValidationAttempt = 0,
    this.isSaving = false,
    this.teachingLanguagesErrorCode,
    this.specializationsErrorCode,
    this.bioErrorCode,
  });

  final TeacherApplication application;

  /// Raw text typed by the user — shown verbatim in the text field.
  final String phoneRaw;

  /// Raw public name typed by the user.
  final String publicDisplayNameRaw;

  /// Suggested name from the signed-in user profile when draft has none saved.
  final String? prefillPublicDisplayName;

  final String? phoneErrorCode;
  final String? publicDisplayNameErrorCode;
  final bool phoneInteracted;
  final bool publicDisplayNameInteracted;
  final bool submitAttempted;
  final int submitValidationAttempt;
  final bool isSaving;
  final String? teachingLanguagesErrorCode;
  final String? specializationsErrorCode;
  final String? bioErrorCode;

  String? get visiblePhoneErrorCode =>
      (phoneInteracted || submitAttempted) ? phoneErrorCode : null;

  String? get visiblePublicDisplayNameErrorCode =>
      (publicDisplayNameInteracted || submitAttempted)
      ? publicDisplayNameErrorCode
      : null;

  String? get visibleTeachingLanguagesErrorCode =>
      submitAttempted ? teachingLanguagesErrorCode : null;

  String? get visibleSpecializationsErrorCode =>
      submitAttempted ? specializationsErrorCode : null;

  String? get visibleBioErrorCode => submitAttempted ? bioErrorCode : null;

  TeacherApplicationEditing applySubmitValidation() {
    final nameToValidate = publicDisplayNameRaw.isNotEmpty
        ? publicDisplayNameRaw
        : (application.publicDisplayName ?? '');
    final String? phoneErr = phoneRaw.isEmpty
        ? TeacherApplicationValidationCodes.phoneRequired
        : phoneErrorCode;
    final publicNameFailure = ValidateTeacherPublicName.failureFor(
      nameToValidate,
    );
    final String? publicNameErr = publicNameFailure?.code;
    final String? languagesErr = application.teachingLanguages.isEmpty
        ? TeacherApplicationValidationCodes.teachingLanguagesRequired
        : null;
    final String? specsErr = application.specializations.isEmpty
        ? TeacherApplicationValidationCodes.specializationsRequired
        : null;
    final String? bioErr =
        application.bio == null || application.bio!.trim().isEmpty
        ? TeacherApplicationValidationCodes.bioRequired
        : null;

    return copyWith(
      submitAttempted: true,
      submitValidationAttempt: submitValidationAttempt + 1,
      phoneErrorCode: phoneErr,
      publicDisplayNameErrorCode: publicNameErr,
      teachingLanguagesErrorCode: languagesErr,
      specializationsErrorCode: specsErr,
      bioErrorCode: bioErr,
    );
  }

  /// Merges in-progress raw field values into [application] before submit.
  ///
  /// Prefilled controller text (e.g. profile display name) may be visible in
  /// the form without a [TeacherApplicationPublicDisplayNameChanged] event;
  /// submit must not silently fail in that case.
  TeacherApplicationEditing withMergedApplicationFields() {
    final countryCode = application.phoneCountryCode ?? 'EG';
    final mergedPhone = phoneRaw.isNotEmpty
        ? PhoneNormalizer.normalize(phoneRaw, countryCode)
        : application.phoneNumber;
    final mergedName = ValidateTeacherPublicName.normalize(
      publicDisplayNameRaw.isNotEmpty
          ? publicDisplayNameRaw
          : application.publicDisplayName,
    );

    return copyWith(
      application: application.copyWith(
        phoneNumber: mergedPhone ?? application.phoneNumber,
        publicDisplayName: mergedName ?? application.publicDisplayName,
      ),
    );
  }

  bool get canSubmit =>
      !isSaving &&
      application.isReadyToSubmit &&
      phoneErrorCode == null &&
      publicDisplayNameErrorCode == null &&
      teachingLanguagesErrorCode == null &&
      specializationsErrorCode == null &&
      bioErrorCode == null;

  int get invalidFieldCount {
    if (!submitAttempted || canSubmit) {
      return 0;
    }
    return validationIssues.length;
  }

  TeacherApplicationEditing copyWith({
    TeacherApplication? application,
    String? phoneRaw,
    String? publicDisplayNameRaw,
    String? prefillPublicDisplayName,
    String? phoneErrorCode,
    bool clearPhoneErrorCode = false,
    String? publicDisplayNameErrorCode,
    bool clearPublicDisplayNameErrorCode = false,
    bool? phoneInteracted,
    bool? publicDisplayNameInteracted,
    bool? submitAttempted,
    int? submitValidationAttempt,
    bool? isSaving,
    String? teachingLanguagesErrorCode,
    bool clearTeachingLanguagesErrorCode = false,
    String? specializationsErrorCode,
    bool clearSpecializationsErrorCode = false,
    String? bioErrorCode,
    bool clearBioErrorCode = false,
  }) => TeacherApplicationEditing(
    application: application ?? this.application,
    phoneRaw: phoneRaw ?? this.phoneRaw,
    publicDisplayNameRaw: publicDisplayNameRaw ?? this.publicDisplayNameRaw,
    prefillPublicDisplayName:
        prefillPublicDisplayName ?? this.prefillPublicDisplayName,
    phoneErrorCode: clearPhoneErrorCode
        ? null
        : (phoneErrorCode ?? this.phoneErrorCode),
    publicDisplayNameErrorCode: clearPublicDisplayNameErrorCode
        ? null
        : (publicDisplayNameErrorCode ?? this.publicDisplayNameErrorCode),
    phoneInteracted: phoneInteracted ?? this.phoneInteracted,
    publicDisplayNameInteracted:
        publicDisplayNameInteracted ?? this.publicDisplayNameInteracted,
    submitAttempted: submitAttempted ?? this.submitAttempted,
    submitValidationAttempt:
        submitValidationAttempt ?? this.submitValidationAttempt,
    isSaving: isSaving ?? this.isSaving,
    teachingLanguagesErrorCode: clearTeachingLanguagesErrorCode
        ? null
        : (teachingLanguagesErrorCode ?? this.teachingLanguagesErrorCode),
    specializationsErrorCode: clearSpecializationsErrorCode
        ? null
        : (specializationsErrorCode ?? this.specializationsErrorCode),
    bioErrorCode: clearBioErrorCode
        ? null
        : (bioErrorCode ?? this.bioErrorCode),
  );

  @override
  List<Object?> get props => [
    application,
    phoneRaw,
    publicDisplayNameRaw,
    prefillPublicDisplayName,
    phoneErrorCode,
    publicDisplayNameErrorCode,
    phoneInteracted,
    publicDisplayNameInteracted,
    submitAttempted,
    submitValidationAttempt,
    isSaving,
    teachingLanguagesErrorCode,
    specializationsErrorCode,
    bioErrorCode,
  ];
}

/// Application is being submitted (network / repo call in flight).
final class TeacherApplicationSubmitting extends TeacherApplicationState {
  const TeacherApplicationSubmitting({required this.application});

  final TeacherApplication application;

  @override
  List<Object?> get props => [application];
}

/// Application has a known status — shows the status screen.
final class TeacherApplicationStatusLoaded extends TeacherApplicationState {
  const TeacherApplicationStatusLoaded({
    required this.application,
    this.isSimulatingApproval = false,
  });

  final TeacherApplication application;
  final bool isSimulatingApproval;

  TeacherApplicationStatusLoaded copyWith({
    TeacherApplication? application,
    bool? isSimulatingApproval,
  }) => TeacherApplicationStatusLoaded(
    application: application ?? this.application,
    isSimulatingApproval: isSimulatingApproval ?? this.isSimulatingApproval,
  );

  @override
  List<Object?> get props => [application, isSimulatingApproval];
}

/// A transient failure — BLoC transitions back to a meaningful state
/// after surfacing this so the screen can show a snackbar.
final class TeacherApplicationFailureState extends TeacherApplicationState {
  const TeacherApplicationFailureState({
    required this.failure,
    required this.previousState,
  });

  final QuranSessionsFailure failure;
  final TeacherApplicationState previousState;

  @override
  List<Object?> get props => [failure, previousState];
}

extension TeacherApplicationEditingValidation on TeacherApplicationEditing {
  List<TilawaFormFieldIssue> get validationIssues {
    final List<TilawaFormFieldIssue> issues = <TilawaFormFieldIssue>[];
    if (phoneErrorCode != null) {
      issues.add(
        TilawaFormFieldIssue(
          fieldId: TeacherApplicationFieldIds.phone,
          errorMessage: phoneErrorCode!,
        ),
      );
    }
    if (publicDisplayNameErrorCode != null) {
      issues.add(
        TilawaFormFieldIssue(
          fieldId: TeacherApplicationFieldIds.publicDisplayName,
          errorMessage: publicDisplayNameErrorCode!,
        ),
      );
    }
    if (teachingLanguagesErrorCode != null) {
      issues.add(
        TilawaFormFieldIssue(
          fieldId: TeacherApplicationFieldIds.teachingLanguages,
          errorMessage: teachingLanguagesErrorCode!,
        ),
      );
    }
    if (specializationsErrorCode != null) {
      issues.add(
        TilawaFormFieldIssue(
          fieldId: TeacherApplicationFieldIds.specializations,
          errorMessage: specializationsErrorCode!,
        ),
      );
    }
    if (bioErrorCode != null) {
      issues.add(
        TilawaFormFieldIssue(
          fieldId: TeacherApplicationFieldIds.bio,
          errorMessage: bioErrorCode!,
        ),
      );
    }
    return issues;
  }
}
