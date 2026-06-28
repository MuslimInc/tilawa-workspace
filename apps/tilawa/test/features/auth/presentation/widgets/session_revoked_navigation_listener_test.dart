import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/services/session_revoked_notifier.dart';
import 'package:tilawa/features/auth/domain/usecases/check_session_validity_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_out.dart';
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

  setUp(() {
    cubit = SessionValidityCubit(
      MockAuthRepository(),
      MockCheckSessionValidityUseCase(),
      MockSignOut(),
      SessionRevokedNotifier(),
    );
  });

  tearDown(() => cubit.close());

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

    expect(find.text('Signed in on another device'), findsOneWidget);
    expect(
      find.text(
        'MeMuslim allows one active device per account for Quran Sessions '
        'security. Your account was opened elsewhere — sign in again on this '
        'device to continue.',
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

      expect(find.text('Signed in on another device'), findsOneWidget);
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

      expect(find.text('Signed in on another device'), findsOneWidget);
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

      expect(find.text('Signed in on another device'), findsOneWidget);
    },
  );
}
