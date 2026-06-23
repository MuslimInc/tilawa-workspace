import '../dtos/user_profile_dto.dart';

/// Remote persistence for Quran Sessions user profiles.
///
/// Implementations may use Firestore, REST, or any other backend.
abstract interface class UserProfileRemoteDataSource {
  /// Returns the profile for [userId], creating a shell document when missing.
  Future<UserProfileDto> getOrCreateProfile(String userId);

  Future<UserProfileDto> updateProfile(UserProfileDto profile);

  Future<void> blockAccount({
    required String userId,
    required String restrictionReason,
  });
}
