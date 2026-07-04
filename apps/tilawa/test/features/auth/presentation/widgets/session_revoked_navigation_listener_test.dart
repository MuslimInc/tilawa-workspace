import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:tilawa/features/auth/data/services/google_sign_in_session_tracker.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/services/session_revoked_notifier.dart';
import 'package:tilawa/features/auth/domain/usecases/check_session_validity_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_out.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/auth/presentation/cubit/session_validity_cubit.dart';
import 'package:tilawa/features/auth/presentation/widgets/session_revoked_navigation_listener.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCheckSessionValidityUseCase extends Mock
    implements CheckSessionValidityUseCase {}

class MockSignOut extends Mock implements SignOut {}

class MockLocalizationBloc
    extends MockBloc<LocalizationEvent, LocalizationState>
    implements LocalizationBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

Widget _materialAppWithL10n({required Widget child}) {
  return MaterialApp(
    navigatorKey: AppRouter.navigatorKey,
    theme: AppTheme.getLightTheme(
      primaryColor: PrimaryColorPreset.defaultPreset.value,
    ),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  late SessionValidityCubit cubit;
  late GoogleSignInSessionTracker signInSessionTracker;
  final GetIt getIt = GetIt.instance;

  setUp(() {
    signInSessionTracker = GoogleSignInSessionTracker();
    cubit = SessionValidityCubit(
      MockAuthRepository(),
      MockCheckSessionValidityUseCase(),
      MockSignOut(),
      SessionRevokedNotifier(),
      signInSessionTracker,
    );
  });

  tearDown(() {
    cubit.close();
    if (getIt.isRegistered<GoogleSignInSessionTracker>()) {
      getIt.unregister<GoogleSignInSessionTracker>();
    }
  });

  testWidgets('shows signed-in-elsewhere dialog when session revoked', (
    tester,
  ) async {
    await tester.pumpWidget(
      BlocProvider<SessionValidityCubit>.value(
        value: cubit,
        child: SessionRevokedNavigationListener(
          child: _materialAppWithL10n(
            child: const Scaffold(body: Text('child')),
          ),
        ),
      ),
    );

    cubit.emit(const SessionValidityState(revoked: true));
    await tester.pumpAndSettle();

    expect(find.text('Signed out on another device'), findsOneWidget);
    expect(
      find.text(
        'You were signed out because this account was used on another device.',
      ),
      findsOneWidget,
    );
    expect(find.text('Sign in again'), findsOneWidget);

    await tester.tap(find.text('Sign in again'));
    await tester.pumpAndSettle();
    expect(find.text('Signed in on another device'), findsNothing);
  });

  testWidgets(
    'resolves l10n via LocalizationBloc when navigator lacks delegates',
    (tester) async {
      final mockLocalizationBloc = MockLocalizationBloc();
      whenListen(
        mockLocalizationBloc,
        Stream<LocalizationState>.empty(),
        initialState: const LocalizationState(locale: Locale('en')),
      );

      await tester.pumpWidget(
        BlocProvider<SessionValidityCubit>.value(
          value: cubit,
          child: BlocProvider<LocalizationBloc>.value(
            value: mockLocalizationBloc,
            child: SessionRevokedNavigationListener(
              child: MaterialApp(
                navigatorKey: AppRouter.navigatorKey,
                home: const Scaffold(body: Text('child')),
              ),
            ),
          ),
        ),
      );

      cubit.emit(const SessionValidityState(revoked: true));
      await tester.pumpAndSettle();

      expect(find.text('Signed out on another device'), findsOneWidget);
    },
  );

  testWidgets(
    'falls back to localized copy via lookup when delegates missing',
    (tester) async {
      await tester.pumpWidget(
        BlocProvider<SessionValidityCubit>.value(
          value: cubit,
          child: SessionRevokedNavigationListener(
            child: MaterialApp(
              navigatorKey: AppRouter.navigatorKey,
              home: const Scaffold(body: Text('child')),
            ),
          ),
        ),
      );

      cubit.emit(const SessionValidityState(revoked: true));
      await tester.pumpAndSettle();

      expect(find.text('Signed out on another device'), findsOneWidget);
    },
  );

  testWidgets(
    'does not crash when listener sits above MaterialApp localizations',
    (tester) async {
      await tester.pumpWidget(
        BlocProvider<SessionValidityCubit>.value(
          value: cubit,
          child: SessionRevokedNavigationListener(
            child: _materialAppWithL10n(
              child: const Scaffold(body: Text('child')),
            ),
          ),
        ),
      );

      cubit.emit(const SessionValidityState(revoked: true));
      await tester.pumpAndSettle();

      expect(find.text('Signed out on another device'), findsOneWidget);
    },
  );

  testWidgets('suppresses dialog while Google sign-in is in flight', (
    tester,
  ) async {
    final tracker = GoogleSignInSessionTracker()..markStarted();
    getIt.registerSingleton<GoogleSignInSessionTracker>(tracker);

    await tester.pumpWidget(
      BlocProvider<SessionValidityCubit>.value(
        value: cubit,
        child: SessionRevokedNavigationListener(
          child: _materialAppWithL10n(
            child: const Scaffold(body: Text('child')),
          ),
        ),
      ),
    );

    cubit.emit(const SessionValidityState(revoked: true));
    await tester.pumpAndSettle();

    expect(find.text('Signed out on another device'), findsNothing);
    tracker.markFinished();
  });

  testWidgets('suppresses dialog while AuthBloc is loading', (tester) async {
    final mockAuthBloc = MockAuthBloc();
    whenListen(
      mockAuthBloc,
      Stream<AuthState>.empty(),
      initialState: const AuthState.loading(),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<SessionValidityCubit>.value(value: cubit),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        ],
        child: SessionRevokedNavigationListener(
          child: _materialAppWithL10n(
            child: const Scaffold(body: Text('child')),
          ),
        ),
      ),
    );

    cubit.emit(const SessionValidityState(revoked: true));
    await tester.pumpAndSettle();

    expect(find.text('Signed out on another device'), findsNothing);
  });

  testWidgets(
    'does not show signed-in-elsewhere after first login when AuthBloc authenticated',
    (tester) async {
      final mockAuthBloc = MockAuthBloc();
      final UserEntity user = UserEntity(
        id: 'user_1',
        email: 'user@example.com',
        displayName: 'User',
        createdAt: DateTime.utc(2024),
      );
      whenListen(
        mockAuthBloc,
        Stream<AuthState>.empty(),
        initialState: AuthState.authenticated(user: user),
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: <BlocProvider<dynamic>>[
            BlocProvider<SessionValidityCubit>.value(value: cubit),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: SessionRevokedNavigationListener(
            child: _materialAppWithL10n(
              child: const Scaffold(body: Text('child')),
            ),
          ),
        ),
      );

      // Session cubit should not emit revoked on first login; verify listener
      // stays silent when only authenticated (no revoked transition).
      cubit.emit(const SessionValidityState(isChecking: false));
      await tester.pumpAndSettle();

      expect(find.text('Signed out on another device'), findsNothing);
    },
  );
}
