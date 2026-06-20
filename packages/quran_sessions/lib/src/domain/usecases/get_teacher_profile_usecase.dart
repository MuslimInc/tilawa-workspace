import 'package:dartz_plus/dartz_plus.dart';

import '../entities/quran_teacher.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/teacher_repository.dart';

class GetTeacherProfileUseCase {
  const GetTeacherProfileUseCase(this._repository);

  final TeacherRepository _repository;

  Future<Either<QuranSessionsFailure, QuranTeacher>> call(
    String teacherId,
  ) => _repository.getTeacherById(teacherId);
}
