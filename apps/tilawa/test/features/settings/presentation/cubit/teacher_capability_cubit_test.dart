import 'dart:async';

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

class _FakeAccessRepository implements TeacherApplicationAccessRepository {
  @override
  Future<Either<QuranSessionsFailure, TeacherApplicationAccess>> resolveForUser(
    String userId,
  ) async {
    return const Right(TeacherApplicationAccess(canApplyAsTeacher: true));
  }
}

class _StubAccessUseCase extends ResolveTeacherApplicationAccessUseCase {
  _StubAccessUseCase() : super(_FakeAccessRepository());
}

/// Capability use case whose [call] completes only when [completer] fires.
class _ControllableCapabilityUseCase
    extends GetCurrentUserTeacherCapabilityUseCase {
  _ControllableCapabilityUseCase()
    : super(
        applicationRepository: _UnimplementedApplicationRepository(),
        profileRepository: _UnimplementedProfileRepository(),
      );

  var callCount = 0;

  /// Completer controlling the most recent [call] future. A new completer is
  /// created on each invocation so async sequences can be driven deterministically.
  Completer<Either<QuranSessionsFailure, TeacherCapability>> completer =
      Completer<Either<QuranSessionsFailure, TeacherCapability>>();

  @override
  Future<Either<QuranSessionsFailure, TeacherCapability>> call(
    String userId,
  ) {
    callCount++;
    completer = Completer<Either<QuranSessionsFailure, TeacherCapability>>();
    return completer.future;
  }
}

/// Auth provider with no signed-in user; [currentUserId] returns null.
class _AnonymousAuthSessionProvider implements AuthSessionProvider {
  const _AnonymousAuthSessionProvider();

  @override
  String? get currentUserId => null;

  @override
  Stream<String?> watchUserId() => const Stream.empty();
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
      scopeGetIt().registerSingleton<ResolveTeacherApplicationAccessUseCase>(
        _StubAccessUseCase(),
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

  blocTest<TeacherCapabilityCubit, SettingsTeacherCapabilityLoadState>(
    'still loads capability when teacher application feature disabled',
    build: () {
      scopeGetIt().registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(
          teacherApplicationEnabled: false,
          teacherApplicationDiscoverability: 'profileOnly',
        ),
      );
      scopeGetIt().registerSingleton<GetCurrentUserTeacherCapabilityUseCase>(
        _StubTeacherCapabilityUseCase([
          const TeacherCapability(state: TeacherCapabilityState.approvedActive),
        ]),
      );
      scopeGetIt().registerSingleton<ResolveTeacherApplicationAccessUseCase>(
        _StubAccessUseCase(),
      );
      return TeacherCapabilityCubit(refreshNotifier: refreshNotifier);
    },
    act: (cubit) async {
      cubit.load();
      await Future<void>.delayed(Duration.zero);
    },
    verify: (cubit) {
      check(cubit.state.hasLoaded).isTrue();
      check(cubit.state.isLoading).isFalse();
      check(
        cubit.state.capability?.state,
      ).equals(TeacherCapabilityState.approvedActive);
    },
  );

  blocTest<TeacherCapabilityCubit, SettingsTeacherCapabilityLoadState>(
    'emits hasLoaded true when user is anonymous',
    build: () {
      scopeGetIt().registerSingleton<AuthSessionProvider>(
        const _AnonymousAuthSessionProvider(),
      );
      scopeGetIt().registerSingleton<GetCurrentUserTeacherCapabilityUseCase>(
        _StubTeacherCapabilityUseCase([
          const TeacherCapability(state: TeacherCapabilityState.approvedActive),
        ]),
      );
      scopeGetIt().registerSingleton<ResolveTeacherApplicationAccessUseCase>(
        _StubAccessUseCase(),
      );
      return TeacherCapabilityCubit(refreshNotifier: refreshNotifier);
    },
    act: (cubit) async {
      cubit.load();
      await Future<void>.delayed(Duration.zero);
    },
    verify: (cubit) {
      check(cubit.state.hasLoaded).isTrue();
      check(cubit.state.isLoading).isFalse();
      check(cubit.state.capability).isNull();
    },
  );

  test(
    'does not emit (and does not throw) when closed during in-flight load',
    () async {
      final useCase = _ControllableCapabilityUseCase();
      scopeGetIt().registerSingleton<GetCurrentUserTeacherCapabilityUseCase>(
        useCase,
      );
      scopeGetIt().registerSingleton<ResolveTeacherApplicationAccessUseCase>(
        _StubAccessUseCase(),
      );

      final notifier = TeacherCapabilityRefreshNotifier();
      final cubit = TeacherCapabilityCubit(refreshNotifier: notifier);

      cubit.load();
      await Future<void>.delayed(Duration.zero);
      check(useCase.callCount).equals(1);
      check(cubit.state.isLoading).isTrue();

      await cubit.close();
      check(cubit.isClosed).isTrue();

      useCase.completer.complete(
        const Right(
          TeacherCapability(state: TeacherCapabilityState.approvedActive),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      check(cubit.state.isLoading).isTrue();
      check(cubit.state.hasLoaded).isFalse();
      check(cubit.state.capability).isNull();
    },
  );

  test(
    'review notification received while closed does not throw and does not '
    'refresh',
    () async {
      final useCase = _ControllableCapabilityUseCase();
      scopeGetIt().registerSingleton<GetCurrentUserTeacherCapabilityUseCase>(
        useCase,
      );
      scopeGetIt().registerSingleton<ResolveTeacherApplicationAccessUseCase>(
        _StubAccessUseCase(),
      );

      final notifier = TeacherCapabilityRefreshNotifier();
      final cubit = TeacherCapabilityCubit(refreshNotifier: notifier);

      cubit.load();
      await Future<void>.delayed(Duration.zero);
      check(useCase.callCount).equals(1);

      useCase.completer.complete(
        const Right(
          TeacherCapability(state: TeacherCapabilityState.approvedActive),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      check(cubit.state.hasLoaded).isTrue();
      check(useCase.callCount).equals(1);

      await cubit.close();
      check(cubit.isClosed).isTrue();

      notifier.resetDedupeForTest();
      notifier.notifyApplicationReviewed('approved');
      await Future<void>.delayed(Duration.zero);

      check(useCase.callCount).equals(1);
      check(cubit.state.isLoading).isFalse();
      check(cubit.state.hasLoaded).isTrue();
      check(
        cubit.state.capability?.state,
      ).equals(TeacherCapabilityState.approvedActive);
    },
  );
}
