import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _MockAuthBloc extends MockCubit<AuthState> implements AuthBloc {}

void main() {
  late _MockAuthBloc authBloc;

  final user = UserEntity(
    id: 'user-1',
    email: 'user@example.com',
    displayName: 'User',
    createdAt: DateTime.utc(2024),
  );

  setUp(() {
    authBloc = _MockAuthBloc();
    when(() => authBloc.state).thenReturn(AuthState.authenticated(user: user));
    when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('logout uses ghost variant for lower emphasis', (tester) async {
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
          child: Scaffold(
            body: SettingsAccountActions(
              onLogout: () {},
              onDeleteAccount: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final TilawaButton logout = tester.widget(
      find.widgetWithText(TilawaButton, 'Logout'),
    );
    final TilawaButton delete = tester.widget(
      find.widgetWithText(TilawaButton, 'Delete account'),
    );
    expect(logout.variant, TilawaButtonVariant.ghost);
    expect(delete.variant, TilawaButtonVariant.dangerOutline);
  });
}
