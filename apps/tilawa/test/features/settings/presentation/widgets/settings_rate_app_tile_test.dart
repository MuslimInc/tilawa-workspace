import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/app_review/presentation/cubit/app_review_cubit.dart';
import 'package:tilawa/features/app_review/presentation/cubit/app_review_state.dart';
import 'package:tilawa/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'test_app_review_cubit.dart';

Widget _buildHarness({
  required AppReviewCubit cubit,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(extensions: [MeMuslimDesignTokens.light()]),
    home: BlocProvider<AppReviewCubit>.value(
      value: cubit,
      child: const Scaffold(
        body: SettingsRateAppTile(),
      ),
    ),
  );
}

void main() {
  testWidgets('shows localized rate row', (WidgetTester tester) async {
    final cubit = TestAppReviewCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildHarness(cubit: cubit));

    expect(find.text('Rate MeMuslim'), findsOneWidget);
  });

  testWidgets('tap requests rating from settings flow', (
    WidgetTester tester,
  ) async {
    final cubit = TestAppReviewCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildHarness(cubit: cubit));
    await tester.tap(find.text('Rate MeMuslim'));
    await tester.pumpAndSettle();

    expect(cubit.rateFromSettingsCalls, 1);
  });

  testWidgets('shows loading indicator while busy', (
    WidgetTester tester,
  ) async {
    final cubit = TestAppReviewCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildHarness(cubit: cubit));
    cubit.emit(
      const AppReviewState(isOpeningStore: true),
    );
    await tester.pump();

    expect(find.byType(TilawaLoadingIndicator), findsOneWidget);
  });

  testWidgets('ignores tap while busy', (WidgetTester tester) async {
    final cubit = TestAppReviewCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildHarness(cubit: cubit));
    cubit.emit(
      const AppReviewState(isOpeningStore: true),
    );
    await tester.pump();

    await tester.tap(find.text('Rate MeMuslim'));
    await tester.pump();

    expect(cubit.rateFromSettingsCalls, 0);
  });
}
