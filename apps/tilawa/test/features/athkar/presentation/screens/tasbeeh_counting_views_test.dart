import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/features/athkar/presentation/cubit/tasbeeh_cubit.dart';
import 'package:tilawa/features/athkar/presentation/cubit/tasbeeh_state.dart';
import 'package:tilawa/features/athkar/presentation/screens/tasbeeh_screen.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/fake_tasbeeh_repository.dart';
import '../../helpers/tasbeeh_test_support.dart';

TasbeehCubit _buildCubit(FakeTasbeehRepository repo) => buildTasbeehCubit(repo);

Widget _buildApp(TasbeehCubit cubit) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => TasbeehScreen(cubit: cubit),
      ),
    ],
  );

  return MaterialApp.router(
    theme: AppTheme.getLightTheme(
      primaryColor: PrimaryColorPreset.defaultPreset.value,
    ),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('en'),
    routerConfig: router,
  );
}

void main() {
  late FakeTasbeehRepository repo;

  setUp(() {
    repo = FakeTasbeehRepository();
  });

  testWidgets('home shows quick count entry and add new action', (
    WidgetTester tester,
  ) async {
    final cubit = _buildCubit(repo);
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildApp(cubit));
    await tester.pump();

    expect(find.text('Quick count'), findsOneWidget);
    expect(find.text('Add new Tasbeeh'), findsOneWidget);
    expect(find.text('Subhan Allah'), findsNothing);
  });

  testWidgets('selected counting shows dhikr title in app bar only', (
    WidgetTester tester,
  ) async {
    final cubit = _buildCubit(repo);
    addTearDown(cubit.close);

    repo.seed(makeDhikr());

    await cubit.loadSavedDhikr();
    cubit.selectDhikrAndStartCounting('1');

    await tester.pumpWidget(_buildApp(cubit));
    await tester.pumpAndSettle();

    expect(find.text('Subhan Allah'), findsOneWidget);
    expect(find.text('Quick count'), findsNothing);
    expect(cubit.state.viewMode, TasbeehViewMode.selectedCounting);
  });
}
