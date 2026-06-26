import '../entities/session_aggregate.dart';
import '../entities/quran_session.dart';
import '../providers/auth_session_provider.dart';
import '../repositories/teacher_profile_repository.dart';
import '../value_objects/actor_role.dart';

/// Resolves whether the signed-in user is the student or teacher for a session.
class ResolveSessionActorRoleUseCase {
  const ResolveSessionActorRoleUseCase({
    required this._authSession,
    required this._teacherProfileRepository,
  });

  final AuthSessionProvider _authSession;
  final TeacherProfileRepository _teacherProfileRepository;

  Future<ActorRole?> forAggregate(SessionAggregate aggregate) {
    return _resolve(
      studentId: aggregate.studentId,
      teacherProfileId: aggregate.teacherId,
    );
  }

  Future<ActorRole?> forSession(QuranSession session) {
    return _resolve(
      studentId: session.studentId,
      teacherProfileId: session.teacherId,
    );
  }

  Future<ActorRole?> _resolve({
    required String studentId,
    required String teacherProfileId,
  }) async {
    final userId = _authSession.currentUserId;
    if (userId == null || userId.isEmpty) return null;
    if (userId == studentId) return ActorRole.student;
    if (userId == teacherProfileId) return ActorRole.teacher;

    final profileResult = await _teacherProfileRepository.getProfileById(
      teacherProfileId,
    );
    return profileResult.fold(
      (_) => null,
      (profile) => profile.userId == userId ? ActorRole.teacher : null,
    );
  }
}
