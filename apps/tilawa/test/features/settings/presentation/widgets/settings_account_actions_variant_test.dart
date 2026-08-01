import 'package:bloc_test/bloc_test.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
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

Widget _app(AuthBloc authBloc, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    theme: AppTheme.getLightTheme(
      primaryColor: PrimaryColorPreset.defaultPreset.value,
    ),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    locale: locale,
    home: BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: Scaffold(
        body: SettingsAccountActions(
          onLogout: () {},
          onDeleteAccount: () {},
        ),
      ),
    ),
  );
}

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

  testWidgets('uses compact account rows with calm destructive emphasis', (
    tester,
  ) async {
    await tester.pumpWidget(_app(authBloc));
    await tester.pump();

    final tiles = tester.widgetList<TilawaSettingsTile>(
      find.byType(TilawaSettingsTile),
    );
    final delete = tiles.singleWhere((tile) => tile.title == 'Delete account');

    expect(find.text('Your account'), findsOneWidget);
    expect(find.byType(TilawaButton), findsNothing);
    expect(tiles, hasLength(2));
    expect(delete.icon, FluentIcons.delete_24_regular);
    expect(
      delete.iconColor,
      Theme.of(tester.element(find.text('Delete account'))).colorScheme.error,
    );
    expect(delete.titleColor, delete.iconColor);
    expect(delete.showDivider, isFalse);
    expect(tiles.every((tile) => !tile.showChevron), isTrue);
  });

  testWidgets('keeps account actions localized in RTL', (tester) async {
    await tester.pumpWidget(_app(authBloc, locale: const Locale('ar')));
    await tester.pump();

    final BuildContext context = tester.element(
      find.byType(SettingsAccountActions),
    );
    final AppLocalizations l10n = AppLocalizations.of(context);

    expect(Directionality.of(context), TextDirection.rtl);
    expect(find.text(l10n.settingsYourAccount), findsOneWidget);
    expect(find.text(l10n.logout), findsOneWidget);
    expect(find.text(l10n.deleteAccount), findsOneWidget);
  });
}
