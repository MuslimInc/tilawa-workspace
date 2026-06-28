import 'package:dartz_plus/dartz_plus.dart';

import '../entities/teacher_profile.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/teacher_profile_repository.dart';

class GetTeacherProfileByIdUseCase {
  const GetTeacherProfileByIdUseCase(this._repository);

  final TeacherProfileRepository _repository;

  Future<Either<QuranSessionsFailure, TeacherProfile>> call(
    String teacherProfileId,
  ) => _repository.getProfileById(teacherProfileId);
}
