import 'package:equatable/equatable.dart';

import '../../../domain/entities/teacher_application.dart';

sealed class TeacherApplicationEvent extends Equatable {
  const TeacherApplicationEvent();

  @override
  List<Object?> get props => [];
}

/// Screen mounted — load existing application or discover no application exists.
final class TeacherApplicationLoadRequested extends TeacherApplicationEvent {
  const TeacherApplicationLoadRequested({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// User taps "Start application" from the no-application state.
final class TeacherApplicationStartRequested extends TeacherApplicationEvent {
  const TeacherApplicationStartRequested({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Phone number field changed.
final class TeacherApplicationPhoneChanged extends TeacherApplicationEvent {
  const TeacherApplicationPhoneChanged(this.phone);

  final String phone;

  @override
  List<Object?> get props => [phone];
}

/// Country code of the phone number changed (ISO 3166-1 alpha-2, e.g. 'EG').
final class TeacherApplicationPhoneCountryCodeChanged
    extends TeacherApplicationEvent {
  const TeacherApplicationPhoneCountryCodeChanged(this.countryCode);

  final String countryCode;

  @override
  List<Object?> get props => [countryCode];
}

/// Preferred contact method changed.
final class TeacherApplicationContactMethodChanged
    extends TeacherApplicationEvent {
  const TeacherApplicationContactMethodChanged(this.method);

  final PreferredContactMethod method;

  @override
  List<Object?> get props => [method];
}

/// User toggled a teaching language (BCP-47 tag).
final class TeacherApplicationLanguageToggled extends TeacherApplicationEvent {
  const TeacherApplicationLanguageToggled(this.language);

  final String language;

  @override
  List<Object?> get props => [language];
}

/// User toggled a specialization key.
final class TeacherApplicationSpecializationToggled
    extends TeacherApplicationEvent {
  const TeacherApplicationSpecializationToggled(this.specialization);

  final String specialization;

  @override
  List<Object?> get props => [specialization];
}

/// Bio text field changed.
final class TeacherApplicationBioChanged extends TeacherApplicationEvent {
  const TeacherApplicationBioChanged(this.bio);

  final String bio;

  @override
  List<Object?> get props => [bio];
}

/// User taps "Submit" — validate and advance to pending.
final class TeacherApplicationSubmitRequested extends TeacherApplicationEvent {
  const TeacherApplicationSubmitRequested();
}

/// DEBUG ONLY — simulates admin approval without a real backend.
///
/// This event is safe to handle in the BLoC because it can only be
/// dispatched from UI that is guarded by [kDebugMode]. It must never
/// be wired to any production code path.
final class TeacherApplicationDebugSimulateApproval
    extends TeacherApplicationEvent {
  const TeacherApplicationDebugSimulateApproval({
    required this.applicationId,
  });

  final String applicationId;

  @override
  List<Object?> get props => [applicationId];
}
