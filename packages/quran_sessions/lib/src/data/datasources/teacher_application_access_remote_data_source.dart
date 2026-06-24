import '../dtos/teacher_application_access_dto.dart';

/// Backend-agnostic read contract for teacher-application access policy.
abstract class TeacherApplicationAccessRemoteDataSource {
  Future<TeacherApplicationAccessSnapshotDto> getAccessSnapshot(String userId);
}
