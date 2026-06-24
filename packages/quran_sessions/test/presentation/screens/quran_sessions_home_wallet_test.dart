import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/fakes/fake_teacher_repository.dart';

void main() {
  testWidgets('hides wallet action when walletEnabled is false', (
    tester,
  ) async {
    final repo = FakeTeacherRepository();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: const [
          QuranSessionsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: BlocProvider(
          create: (_) =>
              TeacherListBloc(GetTeachersUseCase(repo))
                ..add(const LoadTeachersRequested()),
          child: QuranSessionsHomeScreen(
            featureConfig: const QuranSessionsFeatureConfig(
              walletEnabled: false,
            ),
            onMySessions: () {},
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Wallet'), findsNothing);
    expect(find.text('My sessions'), findsOneWidget);
  });

  testWidgets('shows wallet action when walletEnabled is true', (tester) async {
    final repo = FakeTeacherRepository();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: const [
          QuranSessionsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: BlocProvider(
          create: (_) =>
              TeacherListBloc(GetTeachersUseCase(repo))
                ..add(const LoadTeachersRequested()),
          child: QuranSessionsHomeScreen(
            featureConfig: const QuranSessionsFeatureConfig(
              walletEnabled: true,
            ),
            onWallet: () {},
            onMySessions: () {},
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Wallet'), findsOneWidget);
  });
}
