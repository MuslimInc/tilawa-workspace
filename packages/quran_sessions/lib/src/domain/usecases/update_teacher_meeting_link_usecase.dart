import 'package:dartz_plus/dartz_plus.dart';

import '../entities/teacher_profile.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/teacher_profile_repository.dart';
import '../value_objects/external_meeting_url.dart';

/// Saves the verified teacher's external meeting URL on their public profile.
class UpdateTeacherMeetingLinkUseCase {
  const UpdateTeacherMeetingLinkUseCase(this._profiles);

  final TeacherProfileRepository _profiles;

  Future<Either<QuranSessionsFailure, TeacherProfile>> call({
    required String userId,
    required String? externalMeetingUrl,
  }) async {
    final urlFailure = ValidateExternalMeetingUrl.failureFor(
      externalMeetingUrl,
    );
    if (urlFailure != null) {
      return Left(urlFailure);
    }
    final normalized = ValidateExternalMeetingUrl.normalize(externalMeetingUrl);

    final existingResult = await _profiles.getProfileByUserId(userId);
    if (existingResult.isLeft()) {
      return existingResult.map((_) => throw StateError('unreachable'));
    }
    final existing = existingResult.fold(
      (_) => throw StateError('unreachable'),
      (profile) => profile,
    );

    final updated = existing.copyWith(
      externalMeetingUrl: normalized,
      clearExternalMeetingUrl: normalized == null,
      updatedAt: DateTime.now(),
    );

    return _profiles.updatePublicProfile(updated);
  }
}
