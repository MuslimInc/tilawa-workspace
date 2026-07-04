import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/auth/domain/entities/auth_result.dart';
import 'package:tilawa/features/auth/domain/entities/email_auth_failure_key.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/auth/presentation/cubit/email_auth_form_cubit.dart';
import 'package:tilawa/features/auth/presentation/screens/email_auth_screens.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/auth_widget_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  provideAuthBlocDummies();

  final GetIt getIt = GetIt.instance;
  late AuthWidgetTestHarness authHarness;

  setUp(() async {
    TilawaInteractionFeedback.enabled = false;
    authHarness = AuthWidgetTestHarness();
    await getIt.reset();
    getIt.registerFactory<EmailAuthFormCubit>(() => EmailAuthFormCubit());
  });

  tearDown(() {
    authHarness.dispose();
    getIt.reset();
  });

  Future<void> pumpEmailLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: PrimaryColorPreset.defaultPreset.value,
        ),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        builder: (context, child) => TilawaFeedbackHost(child: child!),
        home: BlocProvider<AuthBloc>.value(
          value: authHarness.authBloc,
          child: const EmailLoginScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> enterCredentials(WidgetTester tester) async {
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Password1!',
    );
  }

  group('EmailLoginScreen', () {
    testWidgets('shows validation errors for empty submit', (tester) async {
      await pumpEmailLogin(tester);

      await tester.tap(find.widgetWithText(TilawaButton, 'Sign in'));
      await tester.pump();

      verifyNever(
        authHarness.mockSignInWithEmail(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      );
    });

    testWidgets('dispatches sign-in and reaches authenticated on success', (
      tester,
    ) async {
      when(
        authHarness.mockSignInWithEmail(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer(
        (_) async =>
            AuthResult.success(user: AuthWidgetTestHarness.defaultUser),
      );

      await pumpEmailLogin(tester);
      await enterCredentials(tester);

      await tester.tap(find.widgetWithText(TilawaButton, 'Sign in'));
      await tester.pump();
      await tester.runAsync(() async {
        await authHarness.authBloc.stream.firstWhere(
          (AuthState state) => state is AuthAuthenticated,
        );
      });
      await tester.pump();

      expect(authHarness.authBloc.state, isA<AuthAuthenticated>());
      verify(
        authHarness.mockSignInWithEmail(
          email: 'user@example.com',
          password: 'Password1!',
        ),
      ).called(1);
    });

    testWidgets('shows loading on button while sign-in is in flight', (
      tester,
    ) async {
      when(
        authHarness.mockSignInWithEmail(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        return AuthResult.success(user: AuthWidgetTestHarness.defaultUser);
      });

      await pumpEmailLogin(tester);
      await enterCredentials(tester);

      await tester.tap(find.widgetWithText(TilawaButton, 'Sign in'));
      await tester.pump();
      await tester.runAsync(() async {
        await authHarness.authBloc.stream.firstWhere(
          (AuthState state) => state is AuthLoading,
        );
      });
      await tester.pump();

      expect(
        tester.widget<TilawaButton>(find.byType(TilawaButton)).isLoading,
        isTrue,
      );
    });

    testWidgets('surfaces error toast when sign-in fails', (tester) async {
      when(
        authHarness.mockSignInWithEmail(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer(
        (_) async => const AuthResult.failure(
          message: EmailAuthFailureKey.wrongPassword,
        ),
      );

      await pumpEmailLogin(tester);
      await enterCredentials(tester);

      await tester.tap(find.widgetWithText(TilawaButton, 'Sign in'));
      await tester.pump();
      await tester.runAsync(() async {
        await authHarness.authBloc.stream.firstWhere(
          (AuthState state) => state is AuthError,
        );
      });
      await tester.pump(const Duration(milliseconds: 400));

      expect(authHarness.authBloc.state, isA<AuthError>());
      expect(find.text('Incorrect password'), findsOneWidget);
    });
  });
}
