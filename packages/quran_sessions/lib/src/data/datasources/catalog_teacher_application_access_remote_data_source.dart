import 'package:quran_sessions/src/data/datasources/teacher_application_access_remote_data_source.dart';
import 'package:quran_sessions/src/data/dtos/teacher_application_access_dto.dart';

/// In-memory policy for tests and fake MVP backend.
class CatalogTeacherApplicationAccessRemoteDataSource
    implements TeacherApplicationAccessRemoteDataSource {
  const CatalogTeacherApplicationAccessRemoteDataSource({
    this.policy = const TeacherApplicationAccessPolicyDto(mode: 'none'),
    this.userOverrides = const {},
  });

  final TeacherApplicationAccessPolicyDto policy;
  final Map<String, bool?> userOverrides;

  @override
  Future<TeacherApplicationAccessSnapshotDto> getAccessSnapshot(
    String userId,
  ) async {
    return TeacherApplicationAccessSnapshotDto(
      policy: policy,
      userOverride: userOverrides[userId],
      userRole: 'student',
    );
  }
}
