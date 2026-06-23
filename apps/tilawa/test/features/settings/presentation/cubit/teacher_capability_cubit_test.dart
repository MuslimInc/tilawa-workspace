import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/features/quran_sessions/data/fake_auth_session_provider.dart';
import 'package:tilawa/features/settings/domain/services/teacher_capability_refresh_notifier.dart';
import 'package:tilawa/features/settings/presentation/cubit/teacher_capability_cubit.dart';

import '../../../../support/screen_scope_test_support.dart';

class _StubTeacherCapabilityUseCase
    extends GetCurrentUserTeacherCapabilityUseCase {
  _StubTeacherCapabilityUseCase(this._capabilities)
    : super(
        applicationRepository: _UnimplementedApplicationRepository(),
        profileRepository: _UnimplementedProfileRepository(),
      );

  final List<TeacherCapability> _capabilities;
  var callCount = 0;

  @override
  Future<Either<QuranSessionsFailure, TeacherCapability>> call(
    String userId,
  ) async {
    final index = callCount.clamp(0, _capabilities.length - 1);
    callCount++;
    return Right(_capabilities[index]);
  }
}

class _UnimplementedApplicationRepository
    implements TeacherApplicationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _UnimplementedProfileRepository implements TeacherProfileRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late TeacherCapabilityRefreshNotifier refreshNotifier;

  setUp(() async {
    await resetScopeGetIt();
    refreshNotifier = TeacherCapabilityRefreshNotifier();

    scopeGetIt().registerSingleton<AuthSessionProvider>(
      const FakeAuthSessionProvider(userId: 'user_1'),
    );
    scopeGetIt().registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(
        teacherApplicationEnabled: true,
        teacherApplicationDiscoverability: 'profileOnly',
      ),
    );
  });

  tearDown(() async {
    await resetScopeGetIt();
  });

  blocTest<TeacherCapabilityCubit, SettingsTeacherCapabilityLoadState>(
    'FCM review notification triggers silent capability refresh',
    build: () {
      final useCase = _StubTeacherCapabilityUseCase([
        const TeacherCapability(state: TeacherCapabilityState.pending),
        const TeacherCapability(state: TeacherCapabilityState.approvedActive),
      ]);
      scopeGetIt().registerSingleton<GetCurrentUserTeacherCapabilityUseCase>(
        useCase,
      );
      return TeacherCapabilityCubit(refreshNotifier: refreshNotifier);
    },
    act: (cubit) async {
      cubit.load();
      await Future<void>.delayed(Duration.zero);
      refreshNotifier.resetDedupeForTest();
      refreshNotifier.notifyApplicationReviewed('approved');
      await Future<void>.delayed(Duration.zero);
    },
    verify: (cubit) {
      final useCase =
          scopeGetIt().get<GetCurrentUserTeacherCapabilityUseCase>()
              as _StubTeacherCapabilityUseCase;
      check(useCase.callCount).equals(2);
      check(
        cubit.state.capability?.state,
      ).equals(TeacherCapabilityState.approvedActive);
      check(cubit.state.isLoading).isFalse();
    },
  );
}
