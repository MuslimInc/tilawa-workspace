import 'package:equatable/equatable.dart';

import '../../../domain/entities/teacher_application.dart';
import '../../../domain/failures/quran_sessions_failure.dart';

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
    this.isSaving = false,
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

  /// True while autosave is in flight — disables submit but not field editing.
  final bool isSaving;

  /// The error to show in the UI — null until the user has interacted.
  String? get visiblePhoneError =>
      (phoneInteracted || submitAttempted) ? phoneError : null;

  bool get canSubmit =>
      !isSaving && application.isReadyToSubmit && phoneError == null;

  TeacherApplicationEditing copyWith({
    TeacherApplication? application,
    String? phoneRaw,
    String? phoneError,
    bool clearPhoneError = false,
    bool? phoneInteracted,
    bool? submitAttempted,
    bool? isSaving,
  }) => TeacherApplicationEditing(
    application: application ?? this.application,
    phoneRaw: phoneRaw ?? this.phoneRaw,
    phoneError: clearPhoneError ? null : (phoneError ?? this.phoneError),
    phoneInteracted: phoneInteracted ?? this.phoneInteracted,
    submitAttempted: submitAttempted ?? this.submitAttempted,
    isSaving: isSaving ?? this.isSaving,
  );

  @override
  List<Object?> get props => [
    application,
    phoneRaw,
    phoneError,
    phoneInteracted,
    submitAttempted,
    isSaving,
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
