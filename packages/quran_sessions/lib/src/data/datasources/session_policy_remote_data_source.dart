import '../dtos/session_policy_dto.dart';

abstract interface class SessionPolicyRemoteDataSource {
  Future<SessionPolicyDto> getGlobalPolicy();

  Future<TeacherEligibilityPolicyDto> getTeacherEligibilityPolicy(
    String teacherId,
  );

  Future<void> updateGlobalPolicy(SessionPolicyDto policy);

  Future<void> updateTeacherEligibilityPolicy({
    required String teacherId,
    required TeacherEligibilityPolicyDto policy,
  });
}
