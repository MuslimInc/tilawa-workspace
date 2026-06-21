import '../dtos/teacher_profile_dto.dart';

abstract interface class TeacherProfileRemoteDataSource {
  Future<TeacherProfileDto> getByUserId(String userId);

  Future<TeacherProfileDto> getById(String id);

  Future<TeacherProfileDto> create(TeacherProfileDto profile);

  Future<TeacherProfileDto> update(TeacherProfileDto profile);

  /// Writes only Firestore-rule-allowed public profile fields.
  Future<TeacherProfileDto> updatePublicProfile(TeacherProfileDto profile);

  Future<TeacherProfileDto> deactivate(String id);

  Future<TeacherProfileDto> reactivate(String id);
}
