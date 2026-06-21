import 'package:dartz_plus/dartz_plus.dart';

import '../entities/teacher_profile.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/teacher_profile_repository.dart';
import '../rules/teacher_profile_completeness.dart';
import '../value_objects/teacher_public_name.dart';

/// Saves mutable public [TeacherProfile] fields for an approved teacher.
class SaveTeacherPublicProfileUseCase {
  const SaveTeacherPublicProfileUseCase(this._profiles);

  final TeacherProfileRepository _profiles;

  Future<Either<QuranSessionsFailure, TeacherProfile>> call({
    required String userId,
    required String displayName,
    required String publicBio,
    required List<String> teachingLanguages,
    required List<String> specializations,
    String? avatarUrl,
  }) async {
    final nameFailure = ValidateTeacherPublicName.failureFor(displayName);
    if (nameFailure != null) {
      return Left(nameFailure);
    }
    final trimmedName = ValidateTeacherPublicName.normalize(displayName)!;
    final trimmedBio = publicBio.trim();
    if (trimmedBio.isEmpty) {
      return const Left(
        ValidationFailure(
          field: 'teacherProfile',
          code: 'incomplete',
        ),
      );
    }
    if (teachingLanguages.isEmpty || specializations.isEmpty) {
      return const Left(
        ValidationFailure(
          field: 'teacherProfile',
          code: 'incomplete',
        ),
      );
    }

    final existingResult = await _profiles.getProfileByUserId(userId);
    if (existingResult.isLeft()) {
      return existingResult.map((_) => throw StateError('unreachable'));
    }
    final existing = existingResult.fold(
      (_) => throw StateError(''),
      (profile) => profile,
    );

    final updated = TeacherProfileCompleteness.withComputedVisibility(
      existing.copyWith(
        displayName: trimmedName,
        publicBio: trimmedBio,
        teachingLanguages: teachingLanguages,
        specializations: specializations,
        avatarUrl: avatarUrl ?? existing.avatarUrl,
        updatedAt: DateTime.now(),
      ),
    );

    return _profiles.updatePublicProfile(updated);
  }
}
