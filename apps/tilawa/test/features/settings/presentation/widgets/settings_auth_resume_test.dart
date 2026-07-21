import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/auth/domain/entities/auth_result.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../auth/helpers/auth_widget_test_harness.dart';

/// Settings profile header + real AuthBloc: documents desync window and recovery.
class _SettingsResumeHarness extends StatefulWidget {
  const _SettingsResumeHarness({required this.authBloc});

  final AuthBloc authBloc;

  @override
  State<_SettingsResumeHarness> createState() => _SettingsResumeHarnessState();
}

class _SettingsResumeHarnessState extends State<_SettingsResumeHarness>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Mirrors [AppProviders] cold-start CheckAuthStatus after resume from
      // background when auth may have restored asynchronously.
      widget.authBloc.add(const CheckAuthStatusEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: widget.authBloc,
      child: const Scaffold(body: SettingsProfileHeader()),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  provideAuthBlocDummies();

  late AuthWidgetTestHarness authHarness;
  late TestWidgetsFlutterBinding binding;

  setUp(() {
    authHarness = AuthWidgetTestHarness();
    binding = TestWidgetsFlutterBinding.ensureInitialized();
    when(authHarness.mockGetCurrentUser()).thenReturn(
      AuthWidgetTestHarness.defaultUser,
    );
  });

  tearDown(() {
    authHarness.dispose();
  });

  Future<void> pumpSettingsHarness(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: PrimaryColorPreset.defaultPreset.value,
        ),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        home: _SettingsResumeHarness(authBloc: authHarness.authBloc),
      ),
    );
    await tester.pump();
  }

  group('Settings auth desync window', () {
    testWidgets(
      'shows guest while AuthBloc is initial even if Firebase has user',
      (tester) async {
        await pumpSettingsHarness(tester);

        expect(
          find.text('Sign in to keep your prayer setup and preferences'),
          findsOneWidget,
        );
        expect(find.text('Signed In User'), findsNothing);
      },
    );

    testWidgets(
      'shows guest while AuthBloc is loading before CheckAuthStatus',
      (
        tester,
      ) async {
        when(authHarness.mockSignInWithGoogle()).thenAnswer(
          (_) => Completer<AuthResult>().future,
        );

        await pumpSettingsHarness(tester);

        authHarness.authBloc.add(const SignInWithGoogleEvent());
        await tester.runAsync(() async {
          await authHarness.authBloc.stream.firstWhere(
            (AuthState state) => state is AuthLoading,
          );
        });
        await tester.pump();

        expect(
          find.text('Sign in to keep your prayer setup and preferences'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'recovers profile after CheckAuthStatus resolves Firebase user',
      (
        tester,
      ) async {
        await pumpSettingsHarness(tester);
        expect(
          find.text('Sign in to keep your prayer setup and preferences'),
          findsOneWidget,
        );

        authHarness.authBloc.add(const CheckAuthStatusEvent());
        await tester.runAsync(() async {
          await authHarness.authBloc.stream.firstWhere(
            (AuthState state) => state is AuthAuthenticated,
          );
        });
        await tester.pump();

        expect(find.text('Signed In User'), findsOneWidget);
        expect(
          find.text('Sign in to keep your prayer setup and preferences'),
          findsNothing,
        );
      },
    );

    testWidgets('app resume triggers CheckAuthStatus and clears guest desync', (
      tester,
    ) async {
      await pumpSettingsHarness(tester);
      expect(
        find.text('Sign in to keep your prayer setup and preferences'),
        findsOneWidget,
      );

      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      await tester.runAsync(() async {
        await authHarness.authBloc.stream.firstWhere(
          (AuthState state) => state is AuthAuthenticated,
        );
      });
      await tester.pump();

      expect(find.text('Signed In User'), findsOneWidget);
    });
  });
}
