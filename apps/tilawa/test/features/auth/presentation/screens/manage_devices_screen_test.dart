import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/auth/presentation/screens/manage_devices_screen.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  late _MockAuthBloc authBloc;
  late AppLocalizations l10n;

  setUpAll(() {
    l10n = lookupAppLocalizations(const Locale('en'));
  });

  setUp(() {
    authBloc = _MockAuthBloc();
  });

  testWidgets('guest shows illustrated sign-in state', (tester) async {
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unauthenticated(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: PrimaryColorPreset.defaultPreset.value,
        ),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const ManageDevicesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.manageDevicesGuestTitle), findsOneWidget);
    expect(find.text(l10n.manageDevicesGuestSubtitle), findsOneWidget);
    expect(find.text(l10n.signIn), findsOneWidget);
    expect(find.byType(TilawaIllustratedState), findsOneWidget);
  });
}
