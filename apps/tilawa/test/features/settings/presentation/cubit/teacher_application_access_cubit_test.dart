import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_platform_config_store.dart';
import 'package:tilawa/features/quran_sessions/domain/entities/quran_sessions_platform_config.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/features/quran_sessions/data/fake_auth_session_provider.dart';
import 'package:tilawa/features/settings/presentation/cubit/teacher_application_access_cubit.dart';

import '../../../../support/screen_scope_test_support.dart';

class _StubAccessUseCase extends ResolveTeacherApplicationAccessUseCase {
  _StubAccessUseCase(this._results)
    : super(_FakeTeacherApplicationAccessRepository());

  final List<Either<QuranSessionsFailure, TeacherApplicationAccess>> _results;
  var callCount = 0;

  @override
  Future<Either<QuranSessionsFailure, TeacherApplicationAccess>> call(
    String userId,
  ) async {
    final index = callCount.clamp(0, _results.length - 1);
    callCount++;
    return _results[index];
  }
}

/// Use case whose [call] completes only when [completer] fires.
class _ControllableAccessUseCase
    extends ResolveTeacherApplicationAccessUseCase {
  _ControllableAccessUseCase()
    : super(_FakeTeacherApplicationAccessRepository());

  final Completer<Either<QuranSessionsFailure, TeacherApplicationAccess>>
  completer =
      Completer<Either<QuranSessionsFailure, TeacherApplicationAccess>>();

  @override
  Future<Either<QuranSessionsFailure, TeacherApplicationAccess>> call(
    String userId,
  ) => completer.future;
}

/// Auth provider with no signed-in user; [currentUserId] returns null.
class _AnonymousAuthSessionProvider implements AuthSessionProvider {
  const _AnonymousAuthSessionProvider();

  @override
  String? get currentUserId => null;

  @override
  Stream<String?> watchUserId() => const Stream.empty();
}

class _FakeTeacherApplicationAccessRepository
    implements TeacherApplicationAccessRepository {
  @override
  Future<Either<QuranSessionsFailure, TeacherApplicationAccess>> resolveForUser(
    String userId,
  ) async {
    return const Right(TeacherApplicationAccess(canApplyAsTeacher: false));
  }
}

void main() {
  setUp(() async {
    await resetScopeGetIt();
    scopeGetIt().registerSingleton<AuthSessionProvider>(
      const FakeAuthSessionProvider(userId: 'user_1'),
    );
    scopeGetIt().registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(),
    );
    scopeGetIt().registerSingleton<QuranSessionsPlatformConfigStore>(
      QuranSessionsPlatformConfigStore()..setConfig(
        QuranSessionsPlatformConfig(
          quranSessionsEnabled: true,
          studentEntryEnabled: false,
          bookingEnabled: true,
          bookingMode: 'requiresTutorApproval',
          sessionMode: 'videoOnly',
          enabledCallProviders: {'mock'},
          teacherApplicationEnabled: true,
          teacherApplicationEntryEnabled: true,
          homeTeacherApplicationCardEnabled: false,
          teacherApplicationDiscoverability: 'profileOnly',
        ),
      ),
    );
  });

  tearDown(() async {
    await resetScopeGetIt();
  });

  blocTest<TeacherApplicationAccessCubit, TeacherApplicationAccessState>(
    'emits canApplyAsTeacher when remote allows',
    build: () {
      final useCase = _StubAccessUseCase([
        const Right(TeacherApplicationAccess(canApplyAsTeacher: true)),
      ]);
      scopeGetIt().registerSingleton<ResolveTeacherApplicationAccessUseCase>(
        useCase,
      );
      return TeacherApplicationAccessCubit();
    },
    act: (cubit) async {
      cubit.load();
      await Future<void>.delayed(Duration.zero);
    },
    verify: (cubit) {
      check(cubit.state.canApplyAsTeacher).isTrue();
      check(cubit.state.hasResolved).isTrue();
      check(cubit.state.isLoading).isFalse();
    },
  );

  blocTest<TeacherApplicationAccessCubit, TeacherApplicationAccessState>(
    'fails closed when remote resolution errors',
    build: () {
      final useCase = _StubAccessUseCase([
        const Left(UnknownFailure()),
      ]);
      scopeGetIt().registerSingleton<ResolveTeacherApplicationAccessUseCase>(
        useCase,
      );
      return TeacherApplicationAccessCubit();
    },
    act: (cubit) async {
      cubit.load();
      await Future<void>.delayed(Duration.zero);
    },
    verify: (cubit) {
      check(cubit.state.canApplyAsTeacher).isFalse();
      check(cubit.state.hasResolved).isTrue();
    },
  );

  blocTest<TeacherApplicationAccessCubit, TeacherApplicationAccessState>(
    'emits resolved false when teacher application feature disabled',
    build: () {
      scopeGetIt().registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(),
      );
      scopeGetIt().registerSingleton<QuranSessionsPlatformConfigStore>(
        QuranSessionsPlatformConfigStore()..setConfig(
          QuranSessionsPlatformConfig(
            quranSessionsEnabled: true,
            studentEntryEnabled: false,
            bookingEnabled: true,
            bookingMode: 'requiresTutorApproval',
            sessionMode: 'videoOnly',
            enabledCallProviders: {'mock'},
            teacherApplicationEnabled: false,
            teacherApplicationEntryEnabled: false,
            homeTeacherApplicationCardEnabled: false,
            teacherApplicationDiscoverability: 'profileOnly',
          ),
        ),
      );
      scopeGetIt().registerSingleton<ResolveTeacherApplicationAccessUseCase>(
        _StubAccessUseCase([
          const Right(TeacherApplicationAccess(canApplyAsTeacher: false)),
        ]),
      );
      return TeacherApplicationAccessCubit();
    },
    act: (cubit) async {
      cubit.load();
      await Future<void>.delayed(Duration.zero);
    },
    verify: (cubit) {
      check(cubit.state.canApplyAsTeacher).isFalse();
      check(cubit.state.hasResolved).isTrue();
      check(cubit.state.isLoading).isFalse();
    },
  );

  blocTest<TeacherApplicationAccessCubit, TeacherApplicationAccessState>(
    'emits resolved false when user is anonymous',
    build: () {
      scopeGetIt().registerSingleton<AuthSessionProvider>(
        const _AnonymousAuthSessionProvider(),
      );
      scopeGetIt().registerSingleton<ResolveTeacherApplicationAccessUseCase>(
        _StubAccessUseCase([
          const Right(TeacherApplicationAccess(canApplyAsTeacher: false)),
        ]),
      );
      return TeacherApplicationAccessCubit();
    },
    act: (cubit) async {
      cubit.load();
      await Future<void>.delayed(Duration.zero);
    },
    verify: (cubit) {
      check(cubit.state.canApplyAsTeacher).isFalse();
      check(cubit.state.hasResolved).isTrue();
      check(cubit.state.isLoading).isFalse();
    },
  );

  test(
    'does not emit (and does not throw) when closed during in-flight load',
    () async {
      final useCase = _ControllableAccessUseCase();
      scopeGetIt().registerSingleton<ResolveTeacherApplicationAccessUseCase>(
        useCase,
      );

      final cubit = TeacherApplicationAccessCubit();
      final initialState = cubit.state;

      cubit.load();
      await Future<void>.delayed(Duration.zero);
      check(cubit.state.isLoading).isTrue();

      await cubit.close();
      check(cubit.isClosed).isTrue();

      useCase.completer.complete(
        const Right(TeacherApplicationAccess(canApplyAsTeacher: true)),
      );
      await Future<void>.delayed(Duration.zero);

      check(cubit.state).equals(initialState);
      check(cubit.state.isLoading).isTrue();
      check(cubit.state.hasResolved).isFalse();
    },
  );
}
