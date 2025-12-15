import 'package:bloc_test/bloc_test.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:muzakri/features/auth/domain/entities/user_entity.dart';
import 'package:muzakri/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:muzakri/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:muzakri/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:muzakri/features/settings/presentation/screens/settings_screen.dart';
import 'package:muzakri/features/theme/presentation/cubit/theme_cubit.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';

// Mocks
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockThemeCubit extends MockBloc<ThemeCubit, ThemeState>
    implements ThemeCubit {}

class MockLocalizationBloc
    extends MockBloc<LocalizationEvent, LocalizationState>
    implements LocalizationBloc {}

class MockSettingsCubit extends MockBloc<SettingsCubit, SettingsState>
    implements SettingsCubit {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockThemeCubit mockThemeCubit;
  late MockLocalizationBloc mockLocalizationBloc;
  late MockSettingsCubit mockSettingsCubit;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockThemeCubit = MockThemeCubit();
    mockLocalizationBloc = MockLocalizationBloc();
    mockSettingsCubit = MockSettingsCubit();
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<ThemeCubit>.value(value: mockThemeCubit),
        BlocProvider<LocalizationBloc>.value(value: mockLocalizationBloc),
        BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
      ],
      child: const ScreenUtilPlusInit(
        designSize: Size(375, 812),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: SettingsScreen(),
        ),
      ),
    );
  }

  testWidgets('SettingsScreen displays user info and settings groups', (
    tester,
  ) async {
    final testUser = UserEntity(
      id: '123',
      email: 'test@example.com',
      displayName: 'Test User',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
    );

    when(
      () => mockAuthBloc.state,
    ).thenReturn(AuthState.authenticated(user: testUser));
    when(
      () => mockThemeCubit.state,
    ).thenReturn(const ThemeState(mode: ThemeMode.system));
    when(
      () => mockLocalizationBloc.state,
    ).thenReturn(const LocalizationState(locale: Locale('en')));
    when(() => mockSettingsCubit.state).thenReturn(const SettingsState());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Settings'), findsOneWidget);

    // Verify User Info
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);

    // Verify Sections
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Downloads'), findsOneWidget);

    // Verify Tiles
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Concurrent Downloads'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);

    // Verify Icons
    expect(find.byIcon(FluentIcons.dark_theme_24_regular), findsOneWidget);
    expect(find.byIcon(FluentIcons.local_language_24_regular), findsOneWidget);
    expect(find.byIcon(FluentIcons.arrow_download_24_regular), findsOneWidget);
    expect(find.byIcon(FluentIcons.sign_out_24_regular), findsOneWidget);
  });

  testWidgets('Tap on Theme tile opens bottom sheet', (tester) async {
    when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());
    when(
      () => mockThemeCubit.state,
    ).thenReturn(const ThemeState(mode: ThemeMode.system));
    when(
      () => mockLocalizationBloc.state,
    ).thenReturn(const LocalizationState(locale: Locale('en')));
    when(() => mockSettingsCubit.state).thenReturn(const SettingsState());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Theme'), findsOneWidget);
    expect(find.text('System Default'), findsNWidgets(2));
    expect(find.text('Light Mode'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
  });
}
