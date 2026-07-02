import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_state.dart';
import 'package:tilawa/features/home/presentation/widgets/home_daily_inspiration_section.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_body.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_body_skeleton.dart';
import 'package:tilawa/features/home/presentation/widgets/home_more_actions_group.dart';
import 'package:tilawa/features/home/presentation/widgets/home_primary_actions_section.dart';
import 'package:tilawa/features/home/presentation/widgets/home_quick_tools_section.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/screens/cubit/main_screen_cubit.dart';
import 'package:tilawa/screens/cubit/main_screen_state.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _MockHomeListeningResumeCubit extends MockCubit<HomeListeningResumeState>
    implements HomeListeningResumeCubit {}

class _MockMainScreenCubit extends MockCubit<MainScreenState>
    implements MainScreenCubit {}

void main() {
  testWidgets('renders skeleton placeholders while dashboard load is pending', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: HomeDashboardBody(skeleton: true),
          ),
        ),
      ),
    );
    // Shimmer repeats forever, so pump bounded frames instead of settling.
    await tester.pump();

    expect(find.byType(HomeDashboardBodySkeleton), findsOneWidget);
    expect(find.byType(TilawaSkeleton), findsOneWidget);
    expect(find.byType(HomePrimaryActionsSection), findsNothing);
    expect(find.byType(HomeQuickToolsSection), findsNothing);
    expect(find.byType(HomeMoreActionsGroup), findsNothing);
    expect(find.byType(HomeDailyInspirationSection), findsNothing);
  });

  testWidgets('shows primary actions, quick tools, more, and inspiration', (
    tester,
  ) async {
    final listeningCubit = _MockHomeListeningResumeCubit();
    when(
      () => listeningCubit.state,
    ).thenReturn(const HomeListeningResumeState());
    when(() => listeningCubit.stream).thenAnswer((_) => const Stream.empty());

    final mainScreenCubit = _MockMainScreenCubit();
    when(() => mainScreenCubit.state).thenReturn(const MainScreenState());
    when(() => mainScreenCubit.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: MultiBlocProvider(
              providers: [
                BlocProvider<HomeListeningResumeCubit>.value(
                  value: listeningCubit,
                ),
                BlocProvider<MainScreenCubit>.value(value: mainScreenCubit),
              ],
              child: const HomeDashboardBody(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomeDashboardBody)),
    );

    expect(find.byType(HomePrimaryActionsSection), findsOneWidget);
    expect(find.byType(HomeQuickToolsSection), findsOneWidget);
    expect(find.byType(HomeMoreActionsGroup), findsOneWidget);
    expect(find.byType(HomeDailyInspirationSection), findsOneWidget);

    final double primaryTop = tester
        .getTopLeft(find.byType(HomePrimaryActionsSection))
        .dy;
    final double toolsTop = tester
        .getTopLeft(find.byType(HomeQuickToolsSection))
        .dy;
    final double moreTop = tester
        .getTopLeft(find.byType(HomeMoreActionsGroup))
        .dy;
    final double inspirationTop = tester
        .getTopLeft(find.byType(HomeDailyInspirationSection))
        .dy;

    expect(primaryTop, lessThan(toolsTop));
    expect(toolsTop, lessThan(moreTop));
    expect(moreTop, lessThan(inspirationTop));

    expect(find.text(l10n.homeDailyHabitTitle), findsNothing);
    expect(find.text(l10n.homeTodayTitle), findsNothing);
    expect(find.text(l10n.homeAthkarRitualsTitle), findsNothing);

    expect(find.text(l10n.homeQuickActionsTitle), findsNothing);
    expect(find.text(l10n.homeQuickReciters), findsOneWidget);
    expect(find.text(l10n.homeQuickQuranReader), findsOneWidget);
    expect(find.text(l10n.homeQuickAthkar), findsOneWidget);
    expect(find.text(l10n.homeQuickQibla), findsOneWidget);
    expect(find.text(l10n.homeQuickTasbeeh), findsOneWidget);
    expect(find.text(l10n.bookmarks), findsNothing);

    expect(find.text(l10n.homeQuickPrayer), findsNothing);
    expect(find.text(l10n.homeQuickQuran), findsNothing);
    expect(find.text(l10n.homeQuickQuranReader), findsOneWidget);

    expect(find.text(l10n.listeningHistory), findsOneWidget);
    expect(find.text(l10n.favorites), findsOneWidget);

    expect(find.text(l10n.homeDailyAyahLabel), findsOneWidget);
  });
}
