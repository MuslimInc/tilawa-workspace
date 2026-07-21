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

/// Settings profile header reflects [AuthBloc] only — not live Firebase user.
void main() {
  late _MockAuthBloc authBloc;

  final UserEntity signedInUser = UserEntity(
    id: 'user-1',
    email: 'user@example.com',
    displayName: 'Signed In User',
    createdAt: DateTime.utc(2024),
  );

  setUp(() {
    authBloc = _MockAuthBloc();
  });

  Future<void> pumpHeader(WidgetTester tester, AuthState state) async {
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: state,
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

  testWidgets('shows guest prompt when AuthBloc is unauthenticated', (
    tester,
  ) async {
    await pumpHeader(tester, const AuthState.unauthenticated());

    expect(
      find.text('Sign in to keep your prayer setup and preferences'),
      findsOneWidget,
    );
    expect(find.text('Signed In User'), findsNothing);
    expect(find.byType(TilawaCard), findsOneWidget);
    expect(find.byIcon(TilawaIcons.chevronRightSmall), findsOneWidget);
  });

  testWidgets('shows guest prompt when AuthBloc is still initial', (
    tester,
  ) async {
    await pumpHeader(tester, const AuthState.initial());

    expect(
      find.text('Sign in to keep your prayer setup and preferences'),
      findsOneWidget,
    );
  });

  testWidgets('shows guest prompt when AuthBloc is loading after restart', (
    tester,
  ) async {
    await pumpHeader(tester, const AuthState.loading());

    expect(
      find.text('Sign in to keep your prayer setup and preferences'),
      findsOneWidget,
    );
  });

  testWidgets('shows profile when AuthBloc is authenticated', (tester) async {
    final semanticsHandle = tester.ensureSemantics();

    await pumpHeader(
      tester,
      AuthState.authenticated(user: signedInUser),
    );

    expect(find.text('Signed In User'), findsOneWidget);
    expect(
      find.text('Sign in to keep your prayer setup and preferences'),
      findsNothing,
    );
    expect(find.byType(TilawaCard), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byType(TilawaIconBox), findsOneWidget);
    expect(
      tester.widget<TilawaIconBox>(find.byType(TilawaIconBox)).variant,
      TilawaIconBoxVariant.plain,
    );
    expect(
      tester.widget<TilawaCard>(find.byType(TilawaCard)).onTap,
      isNotNull,
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Signed In User')),
      matchesSemantics(
        label: 'Signed In User',
        value: 'Member since Jan 2024',
        hint: 'Edit Profile. Add a photo and name',
        isButton: true,
        hasTapAction: true,
      ),
    );
    expect(find.text('Add a photo and name'), findsOneWidget);
    semanticsHandle.dispose();
  });
}
