import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/domain/server_action_guard.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../support/fake_network_info.dart';

class _MockAuthBloc extends MockCubit<AuthState> implements AuthBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthBloc authBloc;
  late FakeNetworkInfo networkInfo;
  late ServerActionGuard serverActionGuard;
  var logoutCalls = 0;
  var deleteAccountCalls = 0;

  final user = UserEntity(
    id: 'user-1',
    email: 'user@example.com',
    displayName: 'User',
    createdAt: DateTime.utc(2024),
  );

  setUp(() {
    authBloc = _MockAuthBloc();
    networkInfo = FakeNetworkInfo();
    serverActionGuard = ServerActionGuard(networkInfo);
    logoutCalls = 0;
    deleteAccountCalls = 0;
    when(() => authBloc.state).thenReturn(AuthState.authenticated(user: user));
    when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  tearDown(() async {
    await networkInfo.dispose();
  });

  Future<void> pumpSubject(WidgetTester tester) async {
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
          value: authBloc,
          child: Scaffold(
            body: SettingsAccountActions(
              serverActionGuard: serverActionGuard,
              onLogout: () {
                logoutCalls++;
              },
              onDeleteAccount: () {
                deleteAccountCalls++;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('logout while offline shows message without callback', (
    tester,
  ) async {
    networkInfo.connected = false;

    await pumpSubject(tester);
    await tester.tap(find.text('Logout'));
    await tester.pump();

    expect(logoutCalls, 0);
    expect(
      find.text('No internet connection. Please reconnect and try again.'),
      findsOneWidget,
    );
  });

  testWidgets('delete account while offline shows message without callback', (
    tester,
  ) async {
    networkInfo.connected = false;

    await pumpSubject(tester);
    await tester.tap(find.text('Delete account'));
    await tester.pump();

    expect(deleteAccountCalls, 0);
    expect(
      find.text('No internet connection. Please reconnect and try again.'),
      findsOneWidget,
    );
  });

  testWidgets('online logout invokes callback', (tester) async {
    await pumpSubject(tester);
    await tester.tap(find.text('Logout'));
    await tester.pump();

    expect(logoutCalls, 1);
  });
}
