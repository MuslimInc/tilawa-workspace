import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/auth/presentation/services/auth_post_sign_in_navigation.dart';
import 'package:tilawa/router/app_router_config.dart';

class _FakeGetUserProfileUseCase implements GetUserProfileUseCase {
  _FakeGetUserProfileUseCase(this._profile);

  UserProfile? _profile;

  void setProfile(UserProfile profile) => _profile = profile;

  @override
  Future<Either<QuranSessionsFailure, UserProfile>> call(String userId) async {
    final UserProfile? profile = _profile;
    if (profile == null) {
      return const Left(NotFoundFailure('user'));
    }
    return Right(profile);
  }
}

UserProfile _incompleteProfile(String userId) => UserProfile(
  userId: userId,
  role: UserRole.student,
  accountStatus: AccountStatus.active,
);

UserProfile _completeProfile(String userId) => UserProfile(
  userId: userId,
  role: UserRole.student,
  accountStatus: AccountStatus.active,
  gender: UserGender.male,
  dateOfBirth: DateTime(1990, 1, 1),
  countryCode: 'EG',
  cityId: 'cairo',
);

void main() {
  final GetIt getIt = GetIt.instance;
  late _FakeGetUserProfileUseCase getUserProfile;

  setUp(() {
    getIt.reset();
    getUserProfile = _FakeGetUserProfileUseCase(null);
    getIt.registerSingleton<GetUserProfileUseCase>(getUserProfile);
  });

  tearDown(() async {
    await getIt.reset();
  });

  test('routes incomplete profiles to mandatory profile completion', () async {
    getUserProfile.setProfile(_incompleteProfile('u1'));

    final String destination = await resolvePostAuthDestination('u1');

    check(destination).equals(mandatoryProfileCompletionLocation());
  });

  test('routes complete profiles to home', () async {
    getUserProfile.setProfile(_completeProfile('u1'));

    final String destination = await resolvePostAuthDestination('u1');

    check(destination).equals(const HomeRoute().location);
  });

  test('falls back to home when profile lookup fails', () async {
    final String destination = await resolvePostAuthDestination('u1');

    check(destination).equals(const HomeRoute().location);
  });
}
