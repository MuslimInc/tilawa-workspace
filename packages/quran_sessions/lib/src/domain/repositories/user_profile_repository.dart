import 'package:dartz_plus/dartz_plus.dart';

import '../entities/user_profile.dart';
import '../failures/quran_sessions_failure.dart';

abstract interface class UserProfileRepository {
  Future<Either<QuranSessionsFailure, UserProfile>> getProfile(String userId);

  Future<Either<QuranSessionsFailure, UserProfile>> updateProfile(
    UserProfile profile,
  );

  Future<Either<QuranSessionsFailure, void>> blockAccount({
    required String userId,
    required AccountRestrictionReason reason,
  });
}
