import 'package:quran_sessions/quran_sessions.dart';

import 'fakes/fake_audit_repository.dart';
import 'fakes/fake_session_aggregate_repository.dart';
import 'fakes/fake_session_command_gateway.dart';
import 'fakes/fake_session_mutation_gateway.dart';
import 'fakes/fake_teacher_profile_repository.dart';
import 'fakes/fake_session_notification_gateway.dart';

CancelSessionViaServerUseCase buildCancelSessionViaServerUseCase({
  FakeSessionAggregateRepository? repository,
  FakeSessionCommandGateway? commandGateway,
}) {
  repository ??= FakeSessionAggregateRepository();
  commandGateway ??= FakeSessionCommandGateway();
  return CancelSessionViaServerUseCase(
    cancelSession: CancelSessionUseCase(
      aggregateRepository: repository,
      lifecycleGuard: SessionLifecycleGuard(),
      cancellationPolicy: ConfigurableCancellationPolicy(),
      commandGateway: commandGateway,
      notificationGateway: FakeSessionNotificationGateway(),
      auditRepository: FakeAuditRepository(),
    ),
  );
}

RespondToBookingRequestUseCase buildRespondToBookingRequestUseCase({
  FakeSessionMutationGateway? mutationGateway,
}) {
  return RespondToBookingRequestUseCase(
    mutationGateway ?? FakeSessionMutationGateway(),
  );
}

SubmitSessionBookingUseCase buildSubmitSessionBookingUseCase({
  required GetTeacherAvailabilityUseCase getAvailability,
  FakeSessionMutationGateway? mutationGateway,
  FakeTeacherProfileRepository? teacherProfiles,
  String studentId = 'student_1',
}) {
  return SubmitSessionBookingUseCase(
    mutationGateway: mutationGateway ?? FakeSessionMutationGateway(),
    getAvailability: getAvailability,
    authSession: _FakeAuthSession(studentId),
    teacherProfiles:
        teacherProfiles ??
        FakeTeacherProfileRepository(
          profile: TeacherProfile(
            id: 'teacher_1',
            userId: 'teacher_1',
            displayName: 'Teacher',
            verificationStatus: TeacherVerificationStatus.verified,
            teachingLanguages: const ['ar'],
            specializations: const ['tajweed'],
            averageRating: 0,
            reviewCount: 0,
            isActive: true,
            profileCompleteness: TeacherProfileCompletenessStatus.complete,
            isPubliclyVisible: true,
            externalMeetingUrl: 'https://meet.google.com/test-room',
            createdAt: DateTime.utc(2024, 1, 1),
            updatedAt: DateTime.utc(2024, 1, 2),
          ),
        ),
  );
}

CompleteSessionViaServerUseCase buildCompleteSessionViaServerUseCase({
  FakeSessionMutationGateway? mutationGateway,
}) {
  return CompleteSessionViaServerUseCase(
    mutationGateway: mutationGateway ?? FakeSessionMutationGateway(),
  );
}

class _FakeAuthSession implements AuthSessionProvider {
  _FakeAuthSession(this.userId);
  final String userId;

  @override
  String? get currentUserId => userId;

  @override
  Stream<String?> watchUserId() => Stream.value(userId);
}
