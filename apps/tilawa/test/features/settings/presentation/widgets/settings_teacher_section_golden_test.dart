import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/quran_sessions/data/fake_auth_session_provider.dart';
import 'package:tilawa/features/settings/domain/services/teacher_capability_refresh_notifier.dart';
import 'package:tilawa/features/settings/presentation/widgets/settings_teacher_capability_scope.dart';
import 'package:tilawa/features/settings/presentation/widgets/settings_teaching_on_memuslim_tile.dart';
import 'package:tilawa/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../support/screen_scope_test_support.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _StubTeacherCapabilityUseCase
    extends GetCurrentUserTeacherCapabilityUseCase {
  _StubTeacherCapabilityUseCase(this._capability)
    : super(
        applicationRepository: _UnimplementedApplicationRepository(),
        profileRepository: _UnimplementedProfileRepository(),
      );

  final TeacherCapability _capability;

  @override
  Future<Either<QuranSessionsFailure, TeacherCapability>> call(
    String userId,
  ) async => Right(_capability);
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthBloc mockAuthBloc;

  setUp(() async {
    await resetScopeGetIt();
    mockAuthBloc = _MockAuthBloc();
    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        user: UserEntity(
          id: 'user_1',
          email: 'teacher@example.com',
          displayName: 'Teacher User',
          createdAt: DateTime.utc(2024, 1, 1),
        ),
      ),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

    scopeGetIt().registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(
        teacherApplicationEnabled: true,
        teacherApplicationDiscoverability: 'profileOnly',
      ),
    );
    scopeGetIt().registerSingleton<AuthSessionProvider>(
      const FakeAuthSessionProvider(userId: 'user_1'),
    );
    scopeGetIt().registerSingleton<TeacherCapabilityRefreshNotifier>(
      TeacherCapabilityRefreshNotifier(),
    );
  });

  tearDown(() async {
    await resetScopeGetIt();
  });

  Future<void> pumpSection(
    WidgetTester tester, {
    required TeacherCapability capability,
    required Locale locale,
    required Brightness brightness,
  }) async {
    scopeGetIt().registerSingleton<GetCurrentUserTeacherCapabilityUseCase>(
      _StubTeacherCapabilityUseCase(capability),
    );
    scopeGetIt().registerSingleton<ResolveTeacherApplicationAccessUseCase>(
      _StubAccessUseCase(),
    );

    final theme = brightness == Brightness.dark
        ? AppTheme.getDarkTheme(primaryColor: AppColors.defaultPrimary)
        : AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary);

    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: locale,
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          ...QuranSessionsLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: SettingsTeacherCapabilityScope(
            child: ListView(
              padding: const EdgeInsets.only(top: 12),
              children: const [
                SettingsProfileHeader(),
                SettingsTeachingOnMemuslimSection(),
                _AppearanceSectionStub(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Settings teacher section goldens', () {
    testWidgets('approved teacher layout light ar', (tester) async {
      await pumpSection(
        tester,
        capability: const TeacherCapability(
          state: TeacherCapabilityState.approvedActive,
        ),
        locale: const Locale('ar'),
        brightness: Brightness.light,
      );

      await expectLater(
        find.byType(ListView),
        matchesGoldenFile(
          'goldens/settings_teacher_section_approved_light_ar.png',
        ),
      );
    });

    testWidgets('approved teacher layout dark ar', (tester) async {
      await pumpSection(
        tester,
        capability: const TeacherCapability(
          state: TeacherCapabilityState.approvedActive,
        ),
        locale: const Locale('ar'),
        brightness: Brightness.dark,
      );

      await expectLater(
        find.byType(ListView),
        matchesGoldenFile(
          'goldens/settings_teacher_section_approved_dark_ar.png',
        ),
      );
    });
  });
}

class _AppearanceSectionStub extends StatelessWidget {
  const _AppearanceSectionStub();

  @override
  Widget build(BuildContext context) {
    return TilawaSettingsGroup(
      title: AppLocalizations.of(context).settingsAppearance,
      children: const [
        SizedBox(height: 48, child: ColoredBox(color: Color(0xFFECECEC))),
      ],
    );
  }
}
