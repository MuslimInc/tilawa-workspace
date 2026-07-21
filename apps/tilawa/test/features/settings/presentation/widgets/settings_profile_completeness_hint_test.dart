import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/settings/presentation/widgets/settings_widgets.dart';
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

  Future<void> pumpHeader(WidgetTester tester, UserEntity user) async {
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: AuthState.authenticated(user: user),
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
          child: const Scaffold(body: SettingsProfileHeader()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows completeness hint when photo is missing', (tester) async {
    await pumpHeader(
      tester,
      UserEntity(
        id: 'user-1',
        email: 'user@example.com',
        displayName: 'Ada',
        createdAt: DateTime.utc(2024),
      ),
    );

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text(l10n.settingsProfileCompleteHint), findsOneWidget);
  });

  testWidgets('hides completeness hint when name and photo exist', (
    tester,
  ) async {
    await pumpHeader(
      tester,
      UserEntity(
        id: 'user-1',
        email: 'user@example.com',
        displayName: 'Ada',
        photoUrl: 'https://example.com/a.png',
        createdAt: DateTime.utc(2024),
      ),
    );

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text(l10n.settingsProfileCompleteHint), findsNothing);
  });
}
