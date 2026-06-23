import '../dtos/teacher_application_dto.dart';

abstract interface class TeacherApplicationRemoteDataSource {
  Future<TeacherApplicationDto> getByUserId(String userId);

  Future<TeacherApplicationDto> createDraft(String userId);

  Future<TeacherApplicationDto> saveDraft(TeacherApplicationDto draft);

  Future<TeacherApplicationDto> submit(TeacherApplicationDto application);

  Future<TeacherApplicationDto> approve({
    required String applicationId,
    required String reviewedBy,
  });

  Future<TeacherApplicationDto> reject({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  });

  Future<TeacherApplicationDto> suspend({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  });

  Future<TeacherApplicationDto> revoke({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  });
}
