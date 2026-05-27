import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/features/athkar/domain/services/tasbeeh_target_feedback_service.dart';
import 'package:tilawa/features/athkar/domain/usecases/delete_tasbeeh_dhikr_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_saved_tasbeeh_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/increment_tasbeeh_count_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/reset_tasbeeh_count_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/save_custom_tasbeeh_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/set_tasbeeh_target_count_use_case.dart';
import 'package:tilawa/features/athkar/presentation/cubit/tasbeeh_cubit.dart';
import 'package:tilawa/features/athkar/presentation/cubit/tasbeeh_state.dart';
import 'package:tilawa/features/athkar/presentation/screens/tasbeeh_screen.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/fake_tasbeeh_repository.dart';

class _SilentFeedbackService implements TasbeehTargetFeedbackService {
  @override
  Future<void> onTargetReached() async {}
}

TasbeehCubit _buildCubit(FakeTasbeehRepository repo) => TasbeehCubit(
  GetSavedTasbeehUseCase(repo),
  SaveCustomTasbeehUseCase(repo),
  IncrementTasbeehCountUseCase(repo),
  ResetTasbeehCountUseCase(repo),
  SetTasbeehTargetCountUseCase(repo),
  DeleteTasbeehDhikrUseCase(repo),
  _SilentFeedbackService(),
);

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

  testWidgets('free counting shows history actions but not dhikr title', (
    WidgetTester tester,
  ) async {
    final cubit = _buildCubit(repo);
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildApp(cubit));
    await tester.pump();

    expect(find.text('View saved Tasbeeh'), findsOneWidget);
    expect(find.text('Subhan Allah'), findsNothing);
  });

  testWidgets('selected counting shows dhikr title and hides history actions', (
    WidgetTester tester,
  ) async {
    final cubit = _buildCubit(repo);
    addTearDown(cubit.close);

    repo.seed(makeDhikr());

    await cubit.loadSavedDhikr();
    cubit.selectDhikrAndStartCounting('1');

    await tester.pumpWidget(_buildApp(cubit));
    await tester.pumpAndSettle();

    expect(find.text('Subhan Allah'), findsWidgets);
    expect(find.text('View saved Tasbeeh'), findsNothing);
    expect(cubit.state.viewMode, TasbeehViewMode.selectedCounting);
  });
}
