import 'package:equatable/equatable.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../domain/entities/teacher_application.dart';
import '../../../domain/failures/quran_sessions_failure.dart';
import '../../forms/teacher_application_field_ids.dart';

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
    this.phoneError,
    this.phoneInteracted = false,
    this.submitAttempted = false,
    this.submitValidationAttempt = 0,
    this.isSaving = false,
    this.teachingLanguagesError,
    this.specializationsError,
    this.bioError,
  });

  final TeacherApplication application;

  /// Raw text typed by the user — shown verbatim in the text field.
  /// The BLoC normalizes this to E.164 and stores it in [application.phoneNumber].
  final String phoneRaw;

  /// Non-null when the phone number has a validation error.
  /// Only surfaced in the UI when [phoneInteracted] or [submitAttempted].
  final String? phoneError;

  /// True after the user has touched the phone field at least once.
  final bool phoneInteracted;

  /// True after the user has tapped "Submit" at least once.
  final bool submitAttempted;

  /// Increments on each failed submit validation pass (drives scroll-to-error).
  final int submitValidationAttempt;

  /// True while autosave is in flight — disables submit but not field editing.
  final bool isSaving;

  /// Submit-time teaching languages error copy.
  final String? teachingLanguagesError;

  /// Submit-time specializations error copy.
  final String? specializationsError;

  /// Submit-time bio error copy.
  final String? bioError;

  /// The error to show in the UI — null until the user has interacted.
  String? get visiblePhoneError =>
      (phoneInteracted || submitAttempted) ? phoneError : null;

  String? get visibleTeachingLanguagesError =>
      submitAttempted ? teachingLanguagesError : null;

  String? get visibleSpecializationsError =>
      submitAttempted ? specializationsError : null;

  String? get visibleBioError => submitAttempted ? bioError : null;

  bool get canSubmit =>
      !isSaving &&
      application.isReadyToSubmit &&
      phoneError == null &&
      teachingLanguagesError == null &&
      specializationsError == null &&
      bioError == null;

  int get invalidFieldCount {
    if (!submitAttempted || canSubmit) {
      return 0;
    }
    return validationIssues.length;
  }

  TeacherApplicationEditing applySubmitValidation() {
    final String? phoneErr = phoneRaw.isEmpty
        ? TeacherApplicationValidationMessages.phoneRequired
        : phoneError;
    final String? languagesErr = application.teachingLanguages.isEmpty
        ? TeacherApplicationValidationMessages.teachingLanguagesRequired
        : null;
    final String? specsErr = application.specializations.isEmpty
        ? TeacherApplicationValidationMessages.specializationsRequired
        : null;
    final String? bioErr =
        application.bio == null || application.bio!.trim().isEmpty
        ? TeacherApplicationValidationMessages.bioRequired
        : null;

    return copyWith(
      submitAttempted: true,
      submitValidationAttempt: submitValidationAttempt + 1,
      phoneError: phoneErr,
      teachingLanguagesError: languagesErr,
      specializationsError: specsErr,
      bioError: bioErr,
    );
  }

  TeacherApplicationEditing copyWith({
    TeacherApplication? application,
    String? phoneRaw,
    String? phoneError,
    bool clearPhoneError = false,
    bool? phoneInteracted,
    bool? submitAttempted,
    int? submitValidationAttempt,
    bool? isSaving,
    String? teachingLanguagesError,
    bool clearTeachingLanguagesError = false,
    String? specializationsError,
    bool clearSpecializationsError = false,
    String? bioError,
    bool clearBioError = false,
  }) => TeacherApplicationEditing(
    application: application ?? this.application,
    phoneRaw: phoneRaw ?? this.phoneRaw,
    phoneError: clearPhoneError ? null : (phoneError ?? this.phoneError),
    phoneInteracted: phoneInteracted ?? this.phoneInteracted,
    submitAttempted: submitAttempted ?? this.submitAttempted,
    submitValidationAttempt:
        submitValidationAttempt ?? this.submitValidationAttempt,
    isSaving: isSaving ?? this.isSaving,
    teachingLanguagesError: clearTeachingLanguagesError
        ? null
        : (teachingLanguagesError ?? this.teachingLanguagesError),
    specializationsError: clearSpecializationsError
        ? null
        : (specializationsError ?? this.specializationsError),
    bioError: clearBioError ? null : (bioError ?? this.bioError),
  );

  @override
  List<Object?> get props => [
    application,
    phoneRaw,
    phoneError,
    phoneInteracted,
    submitAttempted,
    submitValidationAttempt,
    isSaving,
    teachingLanguagesError,
    specializationsError,
    bioError,
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
///
/// Covers: pending, approved, rejected, suspended, revoked.
final class TeacherApplicationStatusLoaded extends TeacherApplicationState {
  const TeacherApplicationStatusLoaded({
    required this.application,
    this.isSimulatingApproval = false,
  });

  final TeacherApplication application;

  /// True while the debug "Simulate Approval" call is in flight.
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

  /// The state the BLoC was in before the failure, restored after the snackbar.
  final TeacherApplicationState previousState;

  @override
  List<Object?> get props => [failure, previousState];
}

extension TeacherApplicationEditingValidation on TeacherApplicationEditing {
  List<TilawaFormFieldIssue> get validationIssues {
    final List<TilawaFormFieldIssue> issues = <TilawaFormFieldIssue>[];
    if (phoneError != null) {
      issues.add(
        TilawaFormFieldIssue(
          fieldId: TeacherApplicationFieldIds.phone,
          errorMessage: phoneError!,
        ),
      );
    }
    if (teachingLanguagesError != null) {
      issues.add(
        TilawaFormFieldIssue(
          fieldId: TeacherApplicationFieldIds.teachingLanguages,
          errorMessage: teachingLanguagesError!,
        ),
      );
    }
    if (specializationsError != null) {
      issues.add(
        TilawaFormFieldIssue(
          fieldId: TeacherApplicationFieldIds.specializations,
          errorMessage: specializationsError!,
        ),
      );
    }
    if (bioError != null) {
      issues.add(
        TilawaFormFieldIssue(
          fieldId: TeacherApplicationFieldIds.bio,
          errorMessage: bioError!,
        ),
      );
    }
    return issues;
  }
}
